import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import '../models/student.dart';

/// Generates a PDF money receipt for a payment and lets the user
/// print / save / share it.
class ReceiptService {
  static Future<Uint8List> buildReceiptPdf({
    required Payment payment,
    required Student student,
    required String className,
    required String sectionName,
    required String centerName,
    required String centerPhone,
    required String centerAddress,
    required double totalDueAfter,
  }) async {
    final doc = pw.Document();
    final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

    final fontData = await rootBundle.load('assets/fonts/NotoSansBengali-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        theme: pw.ThemeData.withFont(base: ttf),
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        centerName,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (centerAddress.isNotEmpty)
                        pw.Text(
                          centerAddress,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      if (centerPhone.isNotEmpty)
                        pw.Text(
                          'Phone: $centerPhone',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Divider(),
                pw.Center(
                  child: pw.Text(
                    'MONEY RECEIPT',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 12),
                _row('Receipt No', payment.receiptNo),
                _row('Date', dateFmt.format(payment.date)),
                pw.SizedBox(height: 8),
                _row('Student Name', student.name),
                _row('Roll', student.roll),
                _row('Class', className),
                _row('Section', sectionName),
                _row('Guardian', student.guardianName),
                _row('Phone', student.guardianPhone),
                if (payment.monthFor != null) _row('Month', payment.monthFor!),
                pw.SizedBox(height: 8),
                pw.Divider(),
                _row('Payment Method', payment.method),
                _row(
                  'Amount Paid',
                  'BDT ${payment.amount.toStringAsFixed(2)}',
                  bold: true,
                ),
                _row(
                  'Remaining Due',
                  'BDT ${totalDueAfter.toStringAsFixed(2)}',
                ),
                if (payment.note != null && payment.note!.isNotEmpty)
                  _row('Note', payment.note!),
                pw.SizedBox(height: 32),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Container(width: 120, child: pw.Divider()),
                        pw.Text(
                          'Guardian Signature',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Container(width: 120, child: pw.Divider()),
                        pw.Text(
                          'Authorized Signature',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _row(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> printReceipt(Uint8List pdfBytes) async {
    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }

  static Future<void> shareReceipt(Uint8List pdfBytes, String fileName) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }
}
