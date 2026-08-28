import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/finance_provider.dart';
import '../../providers/student_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';
import '../../utils/due_calculator.dart';
import '../payments/add_payment_screen.dart';
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

    final todayIncome = finance.incomeFor(ReportRange.daily);
    final todayExpense = finance.expenseFor(ReportRange.daily);
    final monthIncome = finance.incomeFor(ReportRange.monthly);
    final monthExpense = finance.expenseFor(ReportRange.monthly);

    double totalDue = 0;
    for (final s in students.students) {
      final paid = finance.totalPaidByStudent(s.id);
      totalDue += DueCalculator.due(s, paid);
    }

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
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            tooltip: 'Add Expense',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExpensesScreen()),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.grey),
                    SizedBox(width: 8),
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
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    'Today Income',
                    fmtMoney(todayIncome),
                    Icons.trending_up_rounded,
                    kAccentGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    'Today Expense',
                    fmtMoney(todayExpense),
                    Icons.trending_down_rounded,
                    kAccentRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    'This Month Income',
                    fmtMoney(monthIncome),
                    Icons.calendar_month_rounded,
                    kPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentDuesList(),
                      ),
                    ),
                    child: _statCard(
                      'Total Due',
                      fmtMoney(totalDue),
                      Icons.report_gmailerrorred_rounded,
                      kAccentOrange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    'Active Student Income',
                    fmtMoney(totalActiveIncome),
                    Icons.person_outline_rounded,
                    kAccentGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    'Inactive Student Income',
                    fmtMoney(totalInactiveIncome),
                    Icons.person_off_outlined,
                    Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _sectionTitle('This Month Profit/Loss'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Icon(
                      (monthIncome - monthExpense) >= 0
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: (monthIncome - monthExpense) >= 0
                          ? kAccentGreen
                          : kAccentRed,
                    ),
                  ],
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

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
