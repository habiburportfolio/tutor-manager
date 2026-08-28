import '../providers/settings_provider.dart';
import 'gateways/sslcommerz_service.dart';
import 'gateways/bkash_service.dart';
import 'gateways/nagad_service.dart';

/// Result of an online payment initiation attempt (session/checkout URL
/// created, ready for the customer to complete payment in a WebView).
class GatewayPaymentResult {
  final bool success;
  final String? checkoutUrl;
  final String? transactionId;
  final String message;
  GatewayPaymentResult({
    required this.success,
    this.checkoutUrl,
    this.transactionId,
    required this.message,
  });
}

/// Orchestrator for the three real Bangladeshi online payment gateways
/// (SSLCommerz, bKash, Nagad). Dispatches to the correct gateway-specific
/// service based on the payment method string selected on the Add Payment
/// screen, using the merchant credentials configured in Settings.
///
/// NOTE (Web preview limitation): bKash and Nagad REST APIs do not send
/// permissive CORS headers, so direct calls from Flutter Web (browser) may
/// fail with a network/CORS error. This does NOT affect the Android APK,
/// where native HTTP calls have no CORS restriction. SSLCommerz generally
/// allows the initial session POST from a browser.
class PaymentGatewayService {
  final SettingsProvider settings;
  PaymentGatewayService(this.settings);

  /// Initiates an online payment for a student's due fee via the selected
  /// gateway method string (e.g. 'SSLCommerz (Online)', 'bKash (Online)',
  /// 'Nagad (Online)'). Returns a checkoutUrl to open in a WebView so the
  /// customer can complete the payment.
  Future<GatewayPaymentResult> initiatePayment({
    required String method,
    required String studentName,
    required String phone,
    required double amount,
    required String orderId,
  }) async {
    if (method.startsWith('SSLCommerz')) {
      final svc = SslCommerzService(settings);
      if (!svc.isConfigured) {
        return GatewayPaymentResult(
          success: false,
          message:
              'SSLCommerz not configured. Please add Store ID / Store Password in Settings.',
        );
      }
      final result = await svc.createSession(
        tranId: orderId,
        amount: amount,
        customerName: studentName,
        customerPhone: phone,
      );
      return GatewayPaymentResult(
        success: result.success,
        checkoutUrl: result.gatewayUrl,
        transactionId: result.sessionKey,
        message: result.message,
      );
    }

    if (method.startsWith('bKash')) {
      final svc = BkashService(settings);
      if (!svc.isConfigured) {
        return GatewayPaymentResult(
          success: false,
          message:
              'bKash not configured. Please add App Key/Secret/Username/Password in Settings.',
        );
      }
      final result = await svc.createPayment(
        merchantInvoiceNumber: orderId,
        amount: amount,
      );
      return GatewayPaymentResult(
        success: result.success,
        checkoutUrl: result.bkashURL,
        transactionId: result.paymentID,
        message: result.message,
      );
    }

    if (method.startsWith('Nagad')) {
      final svc = NagadService(settings);
      if (!svc.isConfigured) {
        return GatewayPaymentResult(
          success: false,
          message:
              'Nagad not configured. Please add Merchant ID / Public Key / Private Key in Settings.',
        );
      }
      final result = await svc.checkout(orderId: orderId, amount: amount);
      return GatewayPaymentResult(
        success: result.success,
        checkoutUrl: result.callbackUrl,
        message: result.message,
      );
    }

    return GatewayPaymentResult(
      success: false,
      message: 'Unknown online payment method: $method',
    );
  }
}
