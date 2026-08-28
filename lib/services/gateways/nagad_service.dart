import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:basic_utils/basic_utils.dart';
import '../../providers/settings_provider.dart';

class NagadPaymentResult {
  final bool success;
  final String? callbackUrl;
  final String message;
  NagadPaymentResult({
    required this.success,
    this.callbackUrl,
    required this.message,
  });
}

/// Real Nagad Payment Gateway (PGW Checkout) integration using the RSA
/// "sensitive data" signature flow described in Nagad's official
/// "Online Payment API Integration Guide v3.3" (the same flow implemented
/// by the reference `nagadpy` / `nagad_payment_gateway` packages):
///
///   1. Build a `sensitiveData` JSON object (merchantId, orderId, challenge,
///      datetime), RSA-encrypt it with Nagad's PUBLIC key, and separately
///      RSA-sign the same plaintext JSON with the MERCHANT's PRIVATE key.
///   2. POST to `/check-out/initialize/{merchantId}/{orderId}` with
///      { dateTime, sensitiveData, signature }.
///   3. Nagad responds with its own encrypted `sensitiveData` containing a
///      `paymentReferenceId` + `challenge` — decrypt it with the merchant's
///      PRIVATE key.
///   4. Build a second sensitiveData object (merchantId, orderId,
///      currencyCode, amount, challenge), encrypt + sign it again, and POST
///      to `/check-out/complete/{paymentReferenceId}` together with the
///      merchantCallbackURL.
///   5. Nagad responds with a `callBackUrl` — redirect the customer there
///      (WebView) to complete authentication/payment on the Nagad app/USSD.
///
/// Credentials required (Settings -> Nagad): Merchant ID, Merchant Private
/// Key (PEM, PKCS1, base64 body only — no BEGIN/END lines needed, they are
/// added automatically), Nagad Public Key (PEM, same format).
class NagadService {
  final SettingsProvider settings;
  NagadService(this.settings);

  String get _baseUrl => settings.paymentLiveMode
      ? 'https://api.mynagad.com/remote-payment-gateway-1.0/api/dfs'
      : 'https://sandbox.mynagad.com/remote-payment-gateway-1.0/api/dfs';

  bool get isConfigured =>
      settings.nagadMerchantId.isNotEmpty &&
      settings.nagadPublicKey.isNotEmpty &&
      settings.nagadPrivateKey.isNotEmpty;

  String _stripPemHeaders(String key) {
    return key
        .replaceAll('-----BEGIN RSA PRIVATE KEY-----', '')
        .replaceAll('-----END RSA PRIVATE KEY-----', '')
        .replaceAll('-----BEGIN PUBLIC KEY-----', '')
        .replaceAll('-----END PUBLIC KEY-----', '')
        .replaceAll('-----BEGIN PRIVATE KEY-----', '')
        .replaceAll('-----END PRIVATE KEY-----', '')
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .trim();
  }

  RSAPrivateKey _privateKey() {
    final body = _stripPemHeaders(settings.nagadPrivateKey);
    final pem =
        '-----BEGIN RSA PRIVATE KEY-----\n$body\n-----END RSA PRIVATE KEY-----';
    return CryptoUtils.rsaPrivateKeyFromPem(pem);
  }

  RSAPublicKey _publicKey() {
    final body = _stripPemHeaders(settings.nagadPublicKey);
    final pem = '-----BEGIN PUBLIC KEY-----\n$body\n-----END PUBLIC KEY-----';
    return CryptoUtils.rsaPublicKeyFromPem(pem);
  }

  String _sign(String plainText) {
    final sig = CryptoUtils.rsaSign(
      _privateKey(),
      Uint8List.fromList(utf8.encode(plainText)),
      algorithmName: 'SHA256withRSA',
    );
    return base64.encode(sig);
  }

  String _encryptWithNagadPublicKey(String plainText) {
    final encrypted = CryptoUtils.rsaEncrypt(plainText, _publicKey());
    return base64.encode(encrypted.codeUnits.map((c) => c & 0xff).toList());
  }

  String _decryptWithMerchantPrivateKey(String base64Cipher) {
    final cipherBytes = base64.decode(base64Cipher);
    final cipherStr = String.fromCharCodes(cipherBytes);
    return CryptoUtils.rsaDecrypt(cipherStr, _privateKey());
  }

  String _challenge(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = DateTime.now().microsecondsSinceEpoch;
    return List.generate(
      length,
      (i) => chars[(rnd + i * 7) % chars.length],
    ).join();
  }

  String _timestamp() {
    final now = DateTime.now();
    String p(int v) => v.toString().padLeft(2, '0');
    return '${now.year}${p(now.month)}${p(now.day)}${p(now.hour)}${p(now.minute)}${p(now.second)}';
  }

  /// Full initialize -> complete checkout flow. Returns a `callbackUrl`
  /// the customer should be redirected to (WebView) to finish payment via
  /// the Nagad app / USSD flow.
  Future<NagadPaymentResult> checkout({
    required String orderId,
    required double amount,
    String merchantCallbackUrl =
        'https://tutormanager.app/payment/nagad/callback',
  }) async {
    if (!isConfigured) {
      return NagadPaymentResult(
        success: false,
        message: 'Nagad Merchant ID / Public Key / Private Key not configured.',
      );
    }
    try {
      final merchantId = settings.nagadMerchantId;
      final now = _timestamp();

      // Step 1: Initialize
      final initSensitive = jsonEncode({
        'merchantId': merchantId,
        'orderId': orderId,
        'challenge': _challenge(40),
        'datetime': now,
      });
      final initBody = {
        'dateTime': now,
        'sensitiveData': _encryptWithNagadPublicKey(initSensitive),
        'signature': _sign(initSensitive),
      };
      final initResp = await http
          .post(
            Uri.parse('$_baseUrl/check-out/initialize/$merchantId/$orderId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(initBody),
          )
          .timeout(const Duration(seconds: 20));
      final initJson = jsonDecode(initResp.body) as Map<String, dynamic>;
      if (kDebugMode) debugPrint('Nagad initialize response: $initJson');

      final initSensitiveResp = initJson['sensitiveData']?.toString();
      if (initSensitiveResp == null || initSensitiveResp.isEmpty) {
        return NagadPaymentResult(
          success: false,
          message:
              initJson['message']?.toString() ?? 'Nagad initialize failed.',
        );
      }
      final decrypted = _decryptWithMerchantPrivateKey(initSensitiveResp);
      final decryptedMap = jsonDecode(decrypted) as Map<String, dynamic>;
      final paymentReferenceId = decryptedMap['paymentReferenceId']
          ?.toString();
      final challenge = decryptedMap['challenge']?.toString();
      if (paymentReferenceId == null || challenge == null) {
        return NagadPaymentResult(
          success: false,
          message: 'Nagad initialize response missing reference/challenge.',
        );
      }

      // Step 2: Complete
      final completeSensitive = jsonEncode({
        'merchantId': merchantId,
        'orderId': orderId,
        'currencyCode': '050', // BDT
        'amount': amount.toStringAsFixed(2),
        'challenge': challenge,
      });
      final completeBody = {
        'dateTime': _timestamp(),
        'sensitiveData': _encryptWithNagadPublicKey(completeSensitive),
        'signature': _sign(completeSensitive),
        'merchantCallbackURL': merchantCallbackUrl,
        'additionalMerchantInfo': <String, dynamic>{},
      };
      final completeResp = await http
          .post(
            Uri.parse('$_baseUrl/check-out/complete/$paymentReferenceId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(completeBody),
          )
          .timeout(const Duration(seconds: 20));
      final completeJson =
          jsonDecode(completeResp.body) as Map<String, dynamic>;
      if (kDebugMode) debugPrint('Nagad complete response: $completeJson');

      final callBackUrl = completeJson['callBackUrl']?.toString();
      final status = completeJson['status']?.toString() ?? '';
      if (callBackUrl != null &&
          callBackUrl.isNotEmpty &&
          status.toLowerCase() == 'success') {
        return NagadPaymentResult(
          success: true,
          callbackUrl: callBackUrl,
          message: 'Nagad checkout session created.',
        );
      }
      return NagadPaymentResult(
        success: false,
        message: completeJson['message']?.toString() ??
            'Nagad checkout initialization failed.',
      );
    } catch (e) {
      return NagadPaymentResult(
        success: false,
        message: 'Nagad request error: $e',
      );
    }
  }

  /// Verify a completed payment server-to-server using the reference id
  /// received via the callback query params.
  Future<bool> verifyPayment(String paymentReferenceId) async {
    try {
      final resp = await http
          .get(Uri.parse('$_baseUrl/verify/payment/$paymentReferenceId'))
          .timeout(const Duration(seconds: 15));
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final status = json['status']?.toString().toLowerCase() ?? '';
      return status == 'success';
    } catch (_) {
      return false;
    }
  }
}
