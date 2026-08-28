import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Launches the native phone dialer / SMS app for a given phone number.
///
/// This is DISTINCT from [SmsService] (the bulk API-based provider used for
/// automated homework alerts) - this uses the device's own dialer/SMS app
/// via `tel:` / `sms:` URI schemes so the coaching center staff can quickly
/// call or text a guardian directly from within the app.
class ContactService {
  static String _cleanPhone(String phone) {
    // Keep leading + but strip other non-digit characters.
    final trimmed = phone.trim();
    final hasPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    return hasPlus ? '+$digits' : digits;
  }

  /// Opens the native phone dialer pre-filled with [phone].
  static Future<void> makePhoneCall(
    BuildContext context,
    String phone,
  ) async {
    final cleaned = _cleanPhone(phone);
    if (cleaned.isEmpty) {
      _showError(context, 'No phone number available.');
      return;
    }
    final uri = Uri(scheme: 'tel', path: cleaned);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        _showError(context, 'Could not open dialer for $cleaned.');
      }
    } catch (_) {
      if (context.mounted) {
        _showError(context, 'Could not open dialer for $cleaned.');
      }
    }
  }

  /// Opens the native SMS app pre-filled with [phone] and optional [body].
  static Future<void> sendSms(
    BuildContext context,
    String phone, {
    String? body,
  }) async {
    final cleaned = _cleanPhone(phone);
    if (cleaned.isEmpty) {
      _showError(context, 'No phone number available.');
      return;
    }
    final uri = Uri(
      scheme: 'sms',
      path: cleaned,
      queryParameters: (body != null && body.isNotEmpty)
          ? {'body': body}
          : null,
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        _showError(context, 'Could not open SMS app for $cleaned.');
      }
    } catch (_) {
      if (context.mounted) {
        _showError(context, 'Could not open SMS app for $cleaned.');
      }
    }
  }

  /// Opens the native SMS app with MULTIPLE recipients pre-filled at once
  /// (group SMS) and an optional shared [body]. Uses the `sms:` scheme with
  /// semicolon-separated numbers, which is the format understood by the
  /// default Android Messaging app (and most other SMS apps) for
  /// broadcasting one message to many recipients in a single compose screen.
  static Future<void> sendGroupSms(
    BuildContext context,
    List<String> phones, {
    String? body,
  }) async {
    final cleaned = phones
        .map(_cleanPhone)
        .where((p) => p.isNotEmpty)
        .toSet() // de-duplicate
        .toList();
    if (cleaned.isEmpty) {
      _showError(context, 'No valid phone numbers to message.');
      return;
    }
    final numbers = cleaned.join(';');
    final query = (body != null && body.isNotEmpty)
        ? '?body=${Uri.encodeComponent(body)}'
        : '';
    final uri = Uri.parse('sms:$numbers$query');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        _showError(context, 'Could not open SMS app for group message.');
      }
    } catch (_) {
      if (context.mounted) {
        _showError(context, 'Could not open SMS app for group message.');
      }
    }
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
