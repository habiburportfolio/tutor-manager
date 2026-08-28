import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../providers/settings_provider.dart';

/// Result of a gateway session-initiation call: the URL the customer must
/// be redirected to (via WebView or external browser) to complete payment.
class GatewaySessionResult {
  final bool success;
  final String? gatewayUrl;
  final String? sessionKey;
  final String message;
  GatewaySessionResult({
    required this.success,
    this.gatewayUrl,
    this.sessionKey,
    required this.message,
  });
}

/// Real SSLCommerz Session API (v4) integration.
/// Docs: https://developer.sslcommerz.com/doc/v4/
///
/// Flow:
///   1. POST store_id/store_passwd/amount/currency/tran_id/customer info to
///      the Session API.
///   2. On success, SSLCommerz returns a `GatewayPageURL` — redirect the
///      customer there (WebView/browser) to complete payment via
///      card/mobile-banking/internet-banking.
///   3. SSLCommerz redirects back to success_url/fail_url/cancel_url which
///      the app intercepts inside the checkout WebView.
class SslCommerzService {
  final SettingsProvider settings;
  SslCommerzService(this.settings);

  String get _baseUrl => settings.paymentLiveMode
      ? 'https://securepay.sslcommerz.com/gwprocess/v4/api.php'
      : 'https://sandbox.sslcommerz.com/gwprocess/v4/api.php';

  bool get isConfigured =>
      settings.sslStoreId.isNotEmpty && settings.sslStorePasswd.isNotEmpty;

  Future<GatewaySessionResult> createSession({
    required String tranId,
    required double amount,
    required String customerName,
    required String customerPhone,
    String successUrl = 'https://tutormanager.app/payment/success',
    String failUrl = 'https://tutormanager.app/payment/fail',
    String cancelUrl = 'https://tutormanager.app/payment/cancel',
  }) async {
    if (!isConfigured) {
      return GatewaySessionResult(
        success: false,
        message:
            'SSLCommerz Store ID / Store Password not configured in Settings.',
      );
    }
    try {
      final body = {
        'store_id': settings.sslStoreId,
        'store_passwd': settings.sslStorePasswd,
        'total_amount': amount.toStringAsFixed(2),
        'currency': 'BDT',
        'tran_id': tranId,
        'product_category': 'Education',
        'product_name': 'Tuition Fee',
        'product_profile': 'general',
        'success_url': successUrl,
        'fail_url': failUrl,
        'cancel_url': cancelUrl,
        'cus_name': customerName.isEmpty ? 'Guardian' : customerName,
        'cus_email': 'guardian@tutormanager.app',
        'cus_add1': 'Dhaka',
        'cus_city': 'Dhaka',
        'cus_postcode': '1000',
        'cus_country': 'Bangladesh',
        'cus_phone': customerPhone.isEmpty ? '01700000000' : customerPhone,
        'shipping_method': 'NO',
        'num_of_item': '1',
      };

      final resp = await http
          .post(Uri.parse(_baseUrl), body: body)
          .timeout(const Duration(seconds: 20));

      if (resp.statusCode != 200) {
        return GatewaySessionResult(
          success: false,
          message: 'SSLCommerz HTTP error: ${resp.statusCode}',
        );
      }

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      if (kDebugMode) {
        debugPrint('SSLCommerz session response: $json');
      }

      final status = json['status']?.toString() ?? '';
      final gatewayUrl = json['GatewayPageURL']?.toString() ?? '';

      if (status.toUpperCase() == 'SUCCESS' && gatewayUrl.isNotEmpty) {
        return GatewaySessionResult(
          success: true,
          gatewayUrl: gatewayUrl,
          sessionKey: json['sessionkey']?.toString(),
          message: 'Session created successfully.',
        );
      }
      return GatewaySessionResult(
        success: false,
        message: json['failedreason']?.toString() ?? 'Session creation failed.',
      );
    } catch (e) {
      return GatewaySessionResult(
        success: false,
        message: 'SSLCommerz request error: $e',
      );
    }
  }

  /// Server-to-server order validation (recommended for production to
  /// confirm the transaction before marking it as paid).
  Future<bool> validateTransaction(String valId) async {
    if (!isConfigured) return false;
    try {
      final validationUrl = settings.paymentLiveMode
          ? 'https://securepay.sslcommerz.com/validator/api/validationserverAPI.php'
          : 'https://sandbox.sslcommerz.com/validator/api/validationserverAPI.php';
      final uri = Uri.parse(validationUrl).replace(
        queryParameters: {
          'val_id': valId,
          'store_id': settings.sslStoreId,
          'store_passwd': settings.sslStorePasswd,
          'format': 'json',
        },
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return false;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final status = json['status']?.toString().toUpperCase() ?? '';
      return status == 'VALID' || status == 'VALIDATED';
    } catch (_) {
      return false;
    }
  }
}
