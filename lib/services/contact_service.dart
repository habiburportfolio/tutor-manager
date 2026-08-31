import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Launches native phone dialer, SMS, WhatsApp, Telegram, and saves
/// contacts to the device phonebook via standard vCard (.vcf) cards.
class ContactService {
  static String cleanPhone(String phone) {
    // Keep leading + but strip other non-digit characters.
    final trimmed = phone.trim();
    final hasPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    return hasPlus ? '+$digits' : digits;
  }

  /// Formats phone number for WhatsApp / Telegram deep links (e.g. 8801XXXXXXXXX)
  static String formatForInternational(String phone) {
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    // If starts with standard BD 01..., convert to 8801...
    if (digits.startsWith('01') && digits.length == 11) {
      digits = '88$digits';
    }
    return digits;
  }

  /// Opens the native phone dialer pre-filled with [phone].
  static Future<void> makePhoneCall(
    BuildContext context,
    String phone,
  ) async {
    final cleaned = cleanPhone(phone);
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
    final cleaned = cleanPhone(phone);
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

  /// Opens WhatsApp directly with a pre-filled message to [phone].
  static Future<void> openWhatsApp(
    BuildContext context,
    String phone, {
    String? message,
  }) async {
    final intlPhone = formatForInternational(phone);
    if (intlPhone.isEmpty) {
      _showError(context, 'No phone number available for WhatsApp.');
      return;
    }
    final textParam = message != null && message.isNotEmpty
        ? '?text=${Uri.encodeComponent(message)}'
        : '';
    final uri = Uri.parse('https://wa.me/$intlPhone$textParam');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        _showError(context, 'Could not open WhatsApp for $intlPhone.');
      }
    } catch (_) {
      if (context.mounted) {
        _showError(context, 'Could not open WhatsApp.');
      }
    }
  }

  /// Opens Telegram chat or share dialog for [phone].
  static Future<void> openTelegram(
    BuildContext context,
    String phone, {
    String? message,
  }) async {
    final intlPhone = formatForInternational(phone);
    if (intlPhone.isEmpty && (message == null || message.isEmpty)) {
      _showError(context, 'No phone or message available for Telegram.');
      return;
    }
    // Try deep link to user number or telegram share link
    Uri uri;
    if (intlPhone.isNotEmpty) {
      uri = Uri.parse('https://t.me/+$intlPhone');
    } else {
      uri = Uri.parse('https://t.me/share/url?url=&text=${Uri.encodeComponent(message!)}');
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        // Fallback to general Telegram share url if direct user link fails
        if (message != null && message.isNotEmpty) {
          final shareUri = Uri.parse(
            'https://t.me/share/url?url=&text=${Uri.encodeComponent(message)}',
          );
          await launchUrl(shareUri, mode: LaunchMode.externalApplication);
        } else {
          _showError(context, 'Could not open Telegram.');
        }
      }
    } catch (_) {
      if (context.mounted) {
        _showError(context, 'Could not open Telegram.');
      }
    }
  }

  /// Saves a student/guardian contact to the device's native contacts/phonebook
  /// by creating a standard vCard (.vcf) file and opening the system contact saver.
  static Future<void> saveContactToDevice(
    BuildContext context, {
    required String name,
    required String phone,
    String? organization,
    String? role,
    String? note,
  }) async {
    final cleaned = cleanPhone(phone);
    if (cleaned.isEmpty) {
      _showError(context, 'No phone number to save.');
      return;
    }

    try {
      final vcardContent = StringBuffer();
      vcardContent.writeln('BEGIN:VCARD');
      vcardContent.writeln('VERSION:3.0');
      vcardContent.writeln('FN:$name');
      vcardContent.writeln('N:$name;;;;');
      if (organization != null && organization.isNotEmpty) {
        vcardContent.writeln('ORG:$organization');
      }
      if (role != null && role.isNotEmpty) {
        vcardContent.writeln('TITLE:$role');
      }
      vcardContent.writeln('TEL;TYPE=CELL:$cleaned');
      if (note != null && note.isNotEmpty) {
        vcardContent.writeln('NOTE:$note');
      }
      vcardContent.writeln('END:VCARD');

      final tempDir = await getTemporaryDirectory();
      final sanitizedName = name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final vcfFile = File('${tempDir.path}/${sanitizedName}_contact.vcf');
      await vcfFile.writeAsString(vcardContent.toString());

      await Share.shareXFiles(
        [
          XFile(
            vcfFile.path,
            mimeType: 'text/vcard',
            name: '$name.vcf',
          ),
        ],
        subject: 'Save $name to Contacts',
        text: 'Contact card for $name ($cleaned)',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saving "$name" ($cleaned) to phone contacts...'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Could not export contact card: $e');
      }
    }
  }

  /// Opens the native SMS app with MULTIPLE recipients pre-filled at once
  static Future<void> sendGroupSms(
    BuildContext context,
    List<String> phones, {
    String? body,
  }) async {
    final cleaned = phones
        .map(cleanPhone)
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

