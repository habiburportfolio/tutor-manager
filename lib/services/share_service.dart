import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Handles sending homework / messages via WhatsApp, Messenger or the
/// native share sheet (which also lists SMS, Email, Bluetooth, Drive, etc).
///
/// NOTE: True automated WhatsApp Business / Messenger Platform APIs need a
/// Meta Developer account + backend server. For a personal coaching app,
/// this share-sheet + wa.me deep-link approach works fully today without
/// any extra account setup, and lets you attach images/PDF/DOC files.
class ShareService {
  /// Opens native share sheet with text + optional file attachments.
  /// Works for WhatsApp, Messenger, Telegram, Email, Bluetooth, etc.
  static Future<void> shareFiles({
    required String text,
    List<String> filePaths = const [],
  }) async {
    if (filePaths.isEmpty) {
      await Share.share(text);
      return;
    }
    final files = filePaths.map((p) => XFile(p)).toList();
    await Share.shareXFiles(files, text: text);
  }

  /// Opens WhatsApp directly with a pre-filled message to a specific phone
  /// number (international format without +, e.g. 8801XXXXXXXXX).
  /// Note: wa.me links cannot attach files directly - only text. For
  /// attachments, use [shareFiles] which lets the user pick WhatsApp from
  /// the share sheet.
  static Future<bool> openWhatsAppChat({
    required String phone,
    required String message,
  }) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse(
      'https://wa.me/$cleaned?text=${Uri.encodeComponent(message)}',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Opens Facebook Messenger with a pre-filled message (text only).
  static Future<bool> openMessenger({required String message}) async {
    // fb-messenger:// scheme opens the app; falls back to share sheet
    // if not installed by caller catching the failure.
    final uri = Uri.parse(
      'https://www.facebook.com/dialog/send?link=&redirect_uri=https://www.facebook.com&app_id=',
    );
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static bool fileExists(String path) => File(path).existsSync();
}
