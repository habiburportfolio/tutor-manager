import '../models/student.dart';

/// Simple due calculator: expected total fee since admission
/// (monthly fee x number of FULL months completed since admission date)
/// minus total amount already paid by the student.
///
/// A student is not considered "due" until at least 1 full month has
/// passed since their admission date. e.g. if admitted on 15 Jan, they
/// owe nothing until 15 Feb (1 month completed), then 1 month's fee is
/// due from 15 Feb to 14 Mar, 2 months' fee from 15 Mar, and so on.
class DueCalculator {
  static int monthsElapsed(DateTime admission, [DateTime? now]) {
    final n = now ?? DateTime.now();
    int months = (n.year - admission.year) * 12 + (n.month - admission.month);
    // If we haven't yet reached the admission day-of-month in the current
    // month, the current (partial) month doesn't count as completed yet.
    if (n.day < admission.day) months -= 1;
    if (months < 0) months = 0;
    return months;
  }

  static double expectedTotal(Student s) {
    return s.monthlyFee * monthsElapsed(s.admissionDate);
  }

  static double due(Student s, double totalPaid) {
    final expected = expectedTotal(s);
    final d = expected - totalPaid;
    return d < 0 ? 0 : d;
  }

  static double advance(Student s, double totalPaid) {
    final expected = expectedTotal(s);
    final a = totalPaid - expected;
    return a < 0 ? 0 : a;
  }
}
