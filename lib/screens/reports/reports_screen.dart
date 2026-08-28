import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/finance_provider.dart';
import '../../utils/theme.dart';
import '../../utils/formatters.dart';
import '../settings/settings_screen.dart';
import '../../widgets/app_logo.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportRange _range = ReportRange.daily;

  final _tabs = const [
    ('Daily', ReportRange.daily),
    ('Weekly', ReportRange.weekly),
    ('Monthly', ReportRange.monthly),
    ('Yearly', ReportRange.yearly),
  ];

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final income = finance.incomeFor(_range);
    final expense = finance.expenseFor(_range);
    final profit = income - expense;

    int trendCount;
    switch (_range) {
      case ReportRange.daily:
        trendCount = 7;
        break;
      case ReportRange.weekly:
        trendCount = 6;
        break;
      case ReportRange.monthly:
        trendCount = 6;
        break;
      case ReportRange.yearly:
        trendCount = 5;
        break;
    }
    final trend = finance.trend(_range, trendCount);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(size: 32),
            const SizedBox(width: 12),
            const Text('Reports'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _tabs
                  .map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(t.$1),
                        selected: _range == t.$2,
                        onSelected: (_) => setState(() => _range = t.$2),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Income',
                  fmtMoney(income),
                  kAccentGreen,
                  Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  'Expense',
                  fmtMoney(expense),
                  kAccentRed,
                  Icons.trending_down_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _statCard(
            'Net Profit / Loss',
            fmtMoney(profit),
            profit >= 0 ? kAccentGreen : kAccentRed,
            profit >= 0
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            wide: true,
          ),
          const SizedBox(height: 24),
          Text('Trend', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(height: 220, child: _buildChart(trend)),
            ),
          ),
          const SizedBox(height: 24),
          Text('Breakdown', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...trend.reversed.map(
            (t) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(t.label),
                subtitle: Row(
                  children: [
                    Text(
                      'Income: ${fmtMoney(t.income)}',
                      style: const TextStyle(color: kAccentGreen, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Expense: ${fmtMoney(t.expense)}',
                      style: const TextStyle(color: kAccentRed, fontSize: 12),
                    ),
                  ],
                ),
                trailing: Text(
                  fmtMoney(t.income - t.expense),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: (t.income - t.expense) >= 0
                        ? kAccentGreen
                        : kAccentRed,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    Color color,
    IconData icon, {
    bool wide = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: wide ? 22 : 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            Icon(icon, color: color),
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
    maxY *= 1.2;

    return BarChart(
      BarChartData(
        maxY: maxY,
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
                width: 8,
                borderRadius: BorderRadius.circular(3),
              ),
              BarChartRodData(
                toY: t.expense,
                color: kAccentRed,
                width: 8,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          );
        }),
      ),
    );
  }
}
