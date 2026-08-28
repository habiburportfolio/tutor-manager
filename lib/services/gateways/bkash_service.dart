import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../providers/settings_provider.dart';

class BkashPaymentResult {
  final bool success;
  final String? bkashURL;
  final String? paymentID;
  final String message;
  BkashPaymentResult({
    required this.success,
    this.bkashURL,
    this.paymentID,
    required this.message,
  });
}

class BkashExecuteResult {
  final bool success;
  final String? trxID;
  final String message;
  BkashExecuteResult({
    required this.success,
    this.trxID,
    required this.message,
  });
}

/// Real bKash Tokenized Checkout (PGW) API integration (v1.2.0-beta).
/// Docs: https://developer.bka.sh/
///
/// Flow: Grant Token -> Create Payment -> (customer approves in bKash
/// webview/app) -> Execute Payment -> Query Payment (optional).
///
/// IMPORTANT (CORS): bKash's sandbox/production REST APIs do not send
/// permissive CORS headers, so calls made directly from a browser (Flutter
/// Web) will be blocked. On native Android (the primary deliverable of
/// this app) there is no CORS restriction — these calls work normally.
/// If running via Flutter Web preview, online bKash payments may fail with
/// a network/CORS error; this is expected and does not affect the Android
/// APK build.
class BkashService {
  final SettingsProvider settings;
  BkashService(this.settings);

  String get _baseUrl => settings.paymentLiveMode
      ? 'https://tokenized.pay.bka.sh/v1.2.0-beta'
      : 'https://tokenized.sandbox.bka.sh/v1.2.0-beta';

  bool get isConfigured =>
      settings.bkashAppKey.isNotEmpty &&
      settings.bkashAppSecret.isNotEmpty &&
      settings.bkashUsername.isNotEmpty &&
      settings.bkashPassword.isNotEmpty;

  String? _idToken;

  Future<String?> _grantToken() async {
    try {
      final resp = await http
          .post(
            Uri.parse('$_baseUrl/tokenized/checkout/token/grant'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'username': settings.bkashUsername,
              'password': settings.bkashPassword,
            },
            body: jsonEncode({
              'app_key': settings.bkashAppKey,
              'app_secret': settings.bkashAppSecret,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      if (kDebugMode) debugPrint('bKash grant token response: $json');
      _idToken = json['id_token']?.toString();
      return _idToken;
    } catch (e) {
      if (kDebugMode) debugPrint('bKash grant token error: $e');
      return null;
    }
  }

  Map<String, String> _authHeaders() => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'authorization': _idToken ?? '',
    'x-app-key': settings.bkashAppKey,
  };

  /// Creates a bKash payment session and returns the `bkashURL` the
  /// customer should be redirected to (WebView) to authorize the payment.
  Future<BkashPaymentResult> createPayment({
    required String merchantInvoiceNumber,
    required double amount,
    String callbackURL = 'https://tutormanager.app/payment/bkash/callback',
  }) async {
    if (!isConfigured) {
      return BkashPaymentResult(
        success: false,
        message: 'bKash App Key/Secret/Username/Password not configured.',
      );
    }
    try {
      final token = await _grantToken();
      if (token == null) {
        return BkashPaymentResult(
          success: false,
          message: 'Failed to obtain bKash auth token. Check credentials.',
        );
      }

      final resp = await http
          .post(
            Uri.parse('$_baseUrl/tokenized/checkout/create'),
            headers: _authHeaders(),
            body: jsonEncode({
              'mode': '0011',
              'payerReference': merchantInvoiceNumber,
              'callbackURL': callbackURL,
              'amount': amount.toStringAsFixed(2),
              'currency': 'BDT',
              'intent': 'sale',
              'merchantInvoiceNumber': merchantInvoiceNumber,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      if (kDebugMode) debugPrint('bKash create payment response: $json');

      final bkashURL = json['bkashURL']?.toString();
      final paymentID = json['paymentID']?.toString();
      if (bkashURL != null && bkashURL.isNotEmpty) {
        return BkashPaymentResult(
          success: true,
          bkashURL: bkashURL,
          paymentID: paymentID,
          message: 'bKash payment session created.',
        );
      }
      return BkashPaymentResult(
        success: false,
        message:
            json['statusMessage']?.toString() ??
            json['errorMessage']?.toString() ??
            'Failed to create bKash payment session.',
      );
    } catch (e) {
      return BkashPaymentResult(
        success: false,
        message: 'bKash request error: $e',
      );
    }
  }

  /// Executes/confirms the payment after the customer approves it in the
  /// bKash checkout webview (call this once the callback URL is hit with
  /// status=success).
  Future<BkashExecuteResult> executePayment(String paymentID) async {
    if (_idToken == null) {
      return BkashExecuteResult(
        success: false,
        message: 'No active bKash session token.',
      );
    }
    try {
      final resp = await http
          .post(
            Uri.parse('$_baseUrl/tokenized/checkout/execute'),
            headers: _authHeaders(),
            body: jsonEncode({'paymentID': paymentID}),
          )
          .timeout(const Duration(seconds: 20));

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      if (kDebugMode) debugPrint('bKash execute payment response: $json');

      final statusCode = json['statusCode']?.toString();
      final trxID = json['trxID']?.toString();
      if (statusCode == '0000' && trxID != null) {
        return BkashExecuteResult(
          success: true,
          trxID: trxID,
          message: 'Payment completed successfully.',
        );
      }
      return BkashExecuteResult(
        success: false,
        message: json['statusMessage']?.toString() ?? 'Payment execution failed.',
      );
    } catch (e) {
      return BkashExecuteResult(
        success: false,
        message: 'bKash execute error: $e',
      );
    }
  }

  Future<Map<String, dynamic>?> queryPayment(String paymentID) async {
    if (_idToken == null) return null;
    try {
      final resp = await http
          .post(
            Uri.parse('$_baseUrl/tokenized/checkout/payment/status'),
            headers: _authHeaders(),
            body: jsonEncode({'paymentID': paymentID}),
          )
          .timeout(const Duration(seconds: 20));
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
