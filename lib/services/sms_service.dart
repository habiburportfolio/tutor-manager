import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../providers/settings_provider.dart';

/// Generic pluggable SMS gateway adapter.
/// Works with ANY provider that exposes a simple HTTP GET/POST API —
/// Grameenphone (GP), Robi, Banglalink, BulkSMSBD, or any local aggregator.
///
/// The user configures the API URL + API key in Settings. This service
/// substitutes {phone}, {message}, {apikey}, {senderid} placeholders in
/// the configured URL/body so it works generically across providers.
class SmsService {
  final SettingsProvider settings;
  SmsService(this.settings);

  /// Sends an SMS to a single phone number.
  /// Returns true on (assumed) success.
  Future<bool> sendSms({required String phone, required String message}) async {
    final apiUrl = settings.smsApiUrl;
    final apiKey = settings.smsApiKey;
    final senderId = settings.smsSenderId;

    if (apiUrl.isEmpty) {
      if (kDebugMode) {
        debugPrint('SMS not sent: no SMS provider configured in Settings.');
      }
      return false;
    }

    try {
      // Build final URL by substituting placeholders.
      final url = apiUrl
          .replaceAll('{phone}', Uri.encodeComponent(phone))
          .replaceAll('{message}', Uri.encodeComponent(message))
          .replaceAll('{apikey}', Uri.encodeComponent(apiKey))
          .replaceAll('{senderid}', Uri.encodeComponent(senderId));

      final response = await http.get(Uri.parse(url));
      if (kDebugMode) {
        debugPrint(
          'SMS API response [${response.statusCode}]: ${response.body}',
        );
      }
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SMS send failed: $e');
      }
      return false;
    }
  }

  /// Sends the same message to multiple phone numbers (bulk homework alerts).
  Future<Map<String, bool>> sendBulkSms({
    required List<String> phones,
    required String message,
  }) async {
    final results = <String, bool>{};
    for (final phone in phones) {
      results[phone] = await sendSms(phone: phone, message: message);
    }
    return results;
  }
}
