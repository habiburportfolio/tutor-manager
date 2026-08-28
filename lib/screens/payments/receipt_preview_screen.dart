import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../services/receipt_service.dart';
import '../../services/share_service.dart';
import '../../utils/theme.dart';

class ReceiptPreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;
  final String fileName;
  final String studentPhone;
  final String studentName;

  const ReceiptPreviewScreen({
    super.key,
    required this.pdfBytes,
    required this.fileName,
    required this.studentPhone,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Money Receipt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () => ReceiptService.printReceipt(pdfBytes),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) async => pdfBytes,
        allowPrinting: true,
        allowSharing: false,
        canDebug: false,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ShareService.openWhatsAppChat(
                    phone: studentPhone,
                    message:
                        'Dear Guardian, this is a payment confirmation for $studentName. Please find the receipt attached.',
                  );
                },
                icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                label: const Text('WhatsApp'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    ReceiptService.shareReceipt(pdfBytes, fileName),
                icon: const Icon(Icons.share),
                label: const Text('Share Receipt'),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kAccentGreen,
        onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        child: const Icon(Icons.check),
      ),
    );
  }
}
