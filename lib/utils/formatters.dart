import 'package:intl/intl.dart';

final currencyFmt = NumberFormat.currency(
  locale: 'en_BD',
  symbol: '৳ ',
  decimalDigits: 0,
);
final dateFmt = DateFormat('dd MMM yyyy');
final dateTimeFmt = DateFormat('dd MMM yyyy, hh:mm a');
final monthFmt = DateFormat('MMMM yyyy');

String fmtMoney(double v) => currencyFmt.format(v);
String fmtDate(DateTime d) => dateFmt.format(d);
String fmtDateTime(DateTime d) => dateTimeFmt.format(d);
