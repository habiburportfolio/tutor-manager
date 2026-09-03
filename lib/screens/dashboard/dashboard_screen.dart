import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/finance_provider.dart';
import '../../providers/student_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';
import '../../utils/due_calculator.dart';
import '../payments/add_payment_screen.dart';
import '../payments/inactive_payments_screen.dart';
import '../payments/other_incomes_screen.dart';
import '../attendance/attendance_screen.dart';
import '../expenses/expenses_screen.dart';
import '../meetings/meetings_screen.dart';
import '../settings/settings_screen.dart';
import '../students/group_contact_screen.dart';
import 'student_dues_list.dart';
import '../../widgets/app_logo.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final students = context.watch<StudentProvider>();

    // Daily
    final todayIncome = finance.incomeFor(ReportRange.daily);
    final todayExpense = finance.expenseFor(ReportRange.daily);

    // Weekly
    final weekIncome = finance.incomeFor(ReportRange.weekly);
    final weekExpense = finance.expenseFor(ReportRange.weekly);

    // Monthly
    final monthIncome = finance.incomeFor(ReportRange.monthly);
    final monthExpense = finance.expenseFor(ReportRange.monthly);

    // Dues
    double totalDue = 0;
    for (final s in students.students) {
      final paid = finance.totalPaidByStudent(s.id);
      totalDue += DueCalculator.due(s, paid);
    }

    // Active vs Inactive Income (from student payments)
    double totalActiveIncome = 0;
    double totalInactiveIncome = 0;
    for (final p in finance.payments) {
      final student = students.byId(p.studentId);
      if (student != null && student.isActive) {
        totalActiveIncome += p.amount;
      } else {
        totalInactiveIncome += p.amount;
      }
    }

    // Other Incomes
    final totalOtherIncome = finance.otherIncomes.fold<double>(
      0.0,
      (sum, o) => sum + o.amount,
    );

    final trend = finance.trend(ReportRange.daily, 7);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(size: 32),
            const SizedBox(width: 12),
            const Text('Tutor Manager'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.how_to_reg_rounded),
            tooltip: 'Student Hajira (হাজিরা)',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AttendanceScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.groups_rounded),
            tooltip: 'Group Call / SMS',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GroupContactScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.video_camera_front_rounded),
            tooltip: 'Virtual Meetings (Zoom / Google Meet)',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MeetingsScreen()),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'hajira') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AttendanceScreen()),
                );
              } else if (value == 'other_income') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OtherIncomesScreen()),
                );
              } else if (value == 'expenses') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExpensesScreen()),
                );
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'hajira',
                child: Row(
                  children: [
                    Icon(Icons.how_to_reg_rounded, color: kPrimary, size: 20),
                    SizedBox(width: 10),
                    Text('Student Hajira (হাজিরা)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'other_income',
                child: Row(
                  children: [
                    Icon(Icons.monetization_on_outlined, color: kAccentGreen, size: 20),
                    SizedBox(width: 10),
                    Text('Other Income (অন্যান্য আয়)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'expenses',
                child: Row(
                  children: [
                    Icon(Icons.remove_circle_outline, color: kAccentRed, size: 20),
                    SizedBox(width: 10),
                    Text('Expenses (খরচ)'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, color: Colors.grey, size: 20),
                    SizedBox(width: 10),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPaymentScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Collect Payment'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          finance.reload();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Quick Access Quick Action Row
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Expanded(
                    child: _quickActionButton(
                      context,
                      icon: Icons.how_to_reg_rounded,
                      label: 'Student Hajira',
                      color: kPrimary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AttendanceScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _quickActionButton(
                      context,
                      icon: Icons.monetization_on_outlined,
                      label: 'Other Income',
                      color: kAccentGreen,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OtherIncomesScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _quickActionButton(
                      context,
                      icon: Icons.receipt_long_rounded,
                      label: 'All Expenses',
                      color: kAccentRed,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ExpensesScreen()),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Row 1: Today Income & Today Expense
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    title: 'Today Income',
                    value: fmtMoney(todayIncome),
                    icon: Icons.trending_up_rounded,
                    color: kAccentGreen,
                    onTap: () => _showBreakdownModal(context, finance, ReportRange.daily),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    title: "Today's Expenses",
                    value: fmtMoney(todayExpense),
                    icon: Icons.trending_down_rounded,
                    color: kAccentRed,
                    onTap: () => _showBreakdownModal(context, finance, ReportRange.daily),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 2: This Week Income & This Week Expense
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    title: 'This Week Income',
                    value: fmtMoney(weekIncome),
                    icon: Icons.view_week_rounded,
                    color: const Color(0xFF0EA5E9),
                    onTap: () => _showBreakdownModal(context, finance, ReportRange.weekly),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    title: 'This Week Expenses',
                    value: fmtMoney(weekExpense),
                    icon: Icons.trending_down_rounded,
                    color: const Color(0xFFF97316),
                    onTap: () => _showBreakdownModal(context, finance, ReportRange.weekly),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 3: This Month Income & This Month Expense
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    title: 'This Month Income',
                    value: fmtMoney(monthIncome),
                    icon: Icons.calendar_month_rounded,
                    color: kPrimary,
                    onTap: () => _showBreakdownModal(context, finance, ReportRange.monthly),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    title: 'This Month Expenses',
                    value: fmtMoney(monthExpense),
                    icon: Icons.calendar_today_rounded,
                    color: kAccentRed,
                    onTap: () => _showBreakdownModal(context, finance, ReportRange.monthly),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 4: Total Due & Active Student Income
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    title: 'Total Due',
                    value: fmtMoney(totalDue),
                    icon: Icons.report_gmailerrorred_rounded,
                    color: kAccentOrange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentDuesList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    title: 'Active Student Income',
                    value: fmtMoney(totalActiveIncome),
                    icon: Icons.person_outline_rounded,
                    color: kAccentGreen,
                    onTap: () => _showBreakdownModal(context, finance, ReportRange.monthly),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 5: Inactive Student Income & Others Income
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    title: 'Inactive Student Income',
                    value: fmtMoney(totalInactiveIncome),
                    icon: Icons.person_off_outlined,
                    color: Colors.grey.shade700,
                    subtitle: 'Tap to view, edit & delete',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InactivePaymentsScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    title: 'Others Income',
                    value: fmtMoney(totalOtherIncome),
                    icon: Icons.monetization_on_outlined,
                    color: const Color(0xFF10B981),
                    subtitle: 'Tap to manage & add',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OtherIncomesScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            _sectionTitle('This Month Profit / Loss'),
            const SizedBox(height: 8),
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showBreakdownModal(context, finance, ReportRange.monthly),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fmtMoney(monthIncome - monthExpense),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: (monthIncome - monthExpense) >= 0
                                  ? kAccentGreen
                                  : kAccentRed,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (monthIncome - monthExpense) >= 0
                                ? 'Net Profit this month (আয় > ব্যয়)'
                                : 'Net Loss this month (ব্যয় > আয়)',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ((monthIncome - monthExpense) >= 0
                                  ? kAccentGreen
                                  : kAccentRed)
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          (monthIncome - monthExpense) >= 0
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: (monthIncome - monthExpense) >= 0
                              ? kAccentGreen
                              : kAccentRed,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            _sectionTitle('Last 7 Days — Income vs Expense'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(height: 200, child: _buildChart(trend)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Students',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${students.totalActiveStudents}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: kPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  );

  Widget _quickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showBreakdownModal(
    BuildContext context,
    FinanceProvider finance,
    ReportRange initialRange,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        ReportRange selectedRange = initialRange;

        return StatefulBuilder(
          builder: (ctx2, setState) {
            final income = finance.incomeFor(selectedRange);
            final studentIncome = finance.studentIncomeFor(selectedRange);
            final otherIncome = finance.otherIncomeFor(selectedRange);
            final expense = finance.expenseFor(selectedRange);
            final profit = income - expense;
            final categoryExpenses = finance.categoryExpenseBreakdown(selectedRange);

            String rangeTitle;
            switch (selectedRange) {
              case ReportRange.daily:
                rangeTitle = "Daily Calculation (আজকের হিসাব)";
                break;
              case ReportRange.weekly:
                rangeTitle = "Weekly Calculation (এই সপ্তাহের হিসাব)";
                break;
              case ReportRange.monthly:
                rangeTitle = "Monthly Calculation (এই মাসের হিসাব)";
                break;
              case ReportRange.yearly:
                rangeTitle = "Yearly Calculation (এই বছরের হিসাব)";
                break;
            }

            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        rangeTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Range Switcher Chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _modalRangeChip('Daily', ReportRange.daily, selectedRange, (r) {
                        setState(() => selectedRange = r);
                      }),
                      _modalRangeChip('Weekly', ReportRange.weekly, selectedRange, (r) {
                        setState(() => selectedRange = r);
                      }),
                      _modalRangeChip('Monthly', ReportRange.monthly, selectedRange, (r) {
                        setState(() => selectedRange = r);
                      }),
                      _modalRangeChip('Yearly', ReportRange.yearly, selectedRange, (r) {
                        setState(() => selectedRange = r);
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Summary 3-Box Row
                  Row(
                    children: [
                      Expanded(
                        child: _modalStatBox(
                          'Total Income (আয়)',
                          fmtMoney(income),
                          kAccentGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _modalStatBox(
                          'Total Expense (ব্যয়)',
                          fmtMoney(expense),
                          kAccentRed,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _modalStatBox(
                          'Net Profit (লাভ)',
                          fmtMoney(profit),
                          profit >= 0 ? kAccentGreen : kAccentRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Income Breakdown Section
                  const Text(
                    'Income Sources (আয়ের উৎস)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Student Fees (শিক্ষার্থীর বেতন)'),
                              Text(
                                fmtMoney(studentIncome),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Others Income (অন্যান্য উৎস)'),
                              Text(
                                fmtMoney(otherIncome),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Expense Category Breakdown Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Expenses by Category (ব্যয়ের ক্যাটাগরি)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pop(ctx2);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExpensesScreen(initialRange: selectedRange),
                            ),
                          );
                        },
                        child: const Text(
                          'View Full Details →',
                          style: TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (categoryExpenses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text('No expenses recorded in this period.', style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ...categoryExpenses.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key, style: const TextStyle(fontSize: 13)),
                            Text(
                              fmtMoney(e.value),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: kAccentRed,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 24),

                  // Quick Action Buttons at the bottom of modal
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx2);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddPaymentScreen()),
                            );
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Payment', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx2);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ExpensesScreen()),
                            );
                          },
                          icon: const Icon(Icons.remove, size: 16),
                          label: const Text('Add Expense', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _modalRangeChip(
    String label,
    ReportRange range,
    ReportRange current,
    Function(ReportRange) onSelect,
  ) {
    final isSelected = range == current;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
      selected: isSelected,
      selectedColor: kPrimary,
      onSelected: (_) => onSelect(range),
    );
  }

  Widget _modalStatBox(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<PeriodStat> trend) {
    double maxY = 100;
    for (final t in trend) {
      if (t.income > maxY) maxY = t.income;
      if (t.expense > maxY) maxY = t.expense;
    }
    maxY = maxY * 1.2;

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= trend.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    trend[idx].label,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(trend.length, (i) {
          final t = trend[i];
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: t.income,
                color: kAccentGreen,
                width: 7,
                borderRadius: BorderRadius.circular(3),
              ),
              BarChartRodData(
                toY: t.expense,
                color: kAccentRed,
                width: 7,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          );
        }),
      ),
    );
  }
}
