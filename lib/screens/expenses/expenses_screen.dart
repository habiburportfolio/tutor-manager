import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/expense.dart';
import '../../utils/theme.dart';
import '../../utils/formatters.dart';

/// Sentinel value used inside the category dropdown to trigger the
/// "add a new custom category" flow.
const String _addNewCategoryValue = '__add_new__';

class ExpensesScreen extends StatefulWidget {
  final ReportRange? initialRange;
  const ExpensesScreen({super.key, this.initialRange});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ReportRange _selectedRange = ReportRange.monthly;
  String _searchQuery = '';
  String? _filterCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.initialRange != null) {
      _selectedRange = widget.initialRange!;
      _tabController.index = 1; // switch to Category Breakdown
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses (ব্যয়ের হিসাব)'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kPrimary,
          tabs: const [
            Tab(text: 'All Expenses', icon: Icon(Icons.list_alt_rounded, size: 18)),
            Tab(text: 'Category Breakdown', icon: Icon(Icons.pie_chart_rounded, size: 18)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExpenseDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllExpensesTab(finance),
          _buildCategoryBreakdownTab(finance),
        ],
      ),
    );
  }

  Widget _buildAllExpensesTab(FinanceProvider finance) {
    final filtered = finance.expenses.where((e) {
      if (_filterCategory != null &&
          e.category.toLowerCase() != _filterCategory!.toLowerCase()) {
        return false;
      }
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return e.title.toLowerCase().contains(q) ||
          e.category.toLowerCase().contains(q) ||
          (e.note ?? '').toLowerCase().contains(q);
    }).toList();

    final totalAmount = filtered.fold<double>(0.0, (sum, e) => sum + e.amount);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).cardColor,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _filterCategory == null
                        ? 'Total Expense (${filtered.length} items)'
                        : 'Category: $_filterCategory',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      Text(
                        fmtMoney(totalAmount),
                        style: const TextStyle(
                          color: kAccentRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (_filterCategory != null) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => setState(() => _filterCategory = null),
                          child: const Icon(Icons.clear, size: 18, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search expenses by title, note, category...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.money_off_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      const Text('No expenses recorded.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final e = filtered[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: kAccentRed.withValues(alpha: 0.12),
                          child: const Icon(
                            Icons.arrow_downward_rounded,
                            color: kAccentRed,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          e.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${e.category} • ${fmtDate(e.date)}'),
                            if (e.note != null && e.note!.isNotEmpty)
                              Text(
                                'Note: ${e.note}',
                                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              fmtMoney(e.amount),
                              style: const TextStyle(
                                color: kAccentRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'edit') {
                                  _showExpenseDialog(context, existing: e);
                                } else if (v == 'delete') {
                                  _confirmDelete(context, finance, e.id);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          ],
                        ),
                        onTap: () => _showExpenseDialog(context, existing: e),
                        onLongPress: () => _confirmDelete(context, finance, e.id),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdownTab(FinanceProvider finance) {
    final breakdown = finance.categoryExpenseBreakdown(_selectedRange);
    final totalSpentInRange = finance.expenseFor(_selectedRange);
    final expensesInRange = finance.expensesForRange(_selectedRange);

    final sortedEntries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String rangeLabel;
    switch (_selectedRange) {
      case ReportRange.daily:
        rangeLabel = "Today's Expenses";
        break;
      case ReportRange.weekly:
        rangeLabel = "This Week's Expenses";
        break;
      case ReportRange.monthly:
        rangeLabel = "This Month's Expenses";
        break;
      case ReportRange.yearly:
        rangeLabel = "This Year's Expenses";
        break;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Range Switcher Chips
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _rangeChip('Daily (দৈনিক)', ReportRange.daily),
              _rangeChip('Weekly (সাপ্তাহিক)', ReportRange.weekly),
              _rangeChip('Monthly (মাসিক)', ReportRange.monthly),
              _rangeChip('Yearly (বাৎসরিক)', ReportRange.yearly),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Overview Summary Card
        Card(
          elevation: 1.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rangeLabel,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fmtMoney(totalSpentInRange),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kAccentRed,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kAccentRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${sortedEntries.length} Categories',
                    style: const TextStyle(
                      color: kAccentRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'Category-wise Breakdown',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        if (sortedEntries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No expenses in this period.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...sortedEntries.map((entry) {
            final catName = entry.key;
            final catAmount = entry.value;
            final percentage = totalSpentInRange == 0
                ? 0.0
                : (catAmount / totalSpentInRange);
            final count = expensesInRange
                .where((e) => e.category.toLowerCase() == catName.toLowerCase())
                .length;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    _filterCategory = catName;
                    _tabController.animateTo(0);
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: kAccentRed,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                catName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '($count items)',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          Text(
                            fmtMoney(catAmount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: kAccentRed,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(kAccentRed),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(percentage * 100).toStringAsFixed(1)}% of total',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const Text(
                            'Tap to view items →',
                            style: TextStyle(fontSize: 11, color: kPrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _rangeChip(String label, ReportRange range) {
    final isSelected = _selectedRange == range;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedColor: kPrimary,
        onSelected: (_) => setState(() => _selectedRange = range),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    FinanceProvider finance,
    String id,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              finance.deleteExpense(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: kAccentRed)),
          ),
        ],
      ),
    );
  }

  void _showExpenseDialog(BuildContext context, {Expense? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title);
    final amountCtrl = TextEditingController(
      text: existing != null ? existing.amount.toString() : '',
    );
    final noteCtrl = TextEditingController(text: existing?.note);
    final finance = context.read<FinanceProvider>();
    final settings = context.read<SettingsProvider>();

    String category = existing?.category ?? settings.allExpenseCategories.first;
    DateTime date = existing?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final categoryOptions = [
            ...settings.allExpenseCategories,
            if (!settings.allExpenseCategories.contains(category)) category,
          ];

          Future<void> pickDate() async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: date,
              firstDate: DateTime(2015),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => date = picked);
          }

          Future<void> promptNewCategory() async {
            final newCatCtrl = TextEditingController();
            final added = await showDialog<String>(
              context: ctx,
              builder: (ctx2) => AlertDialog(
                title: const Text('Add New Category'),
                content: TextField(
                  controller: newCatCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Category Name'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx2),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final name = newCatCtrl.text.trim();
                      if (name.isEmpty) return;
                      Navigator.pop(ctx2, name);
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            );
            if (added != null && added.isNotEmpty) {
              await settings.addCustomExpenseCategory(added);
              setState(() => category = added);
            }
          }

          return AlertDialog(
            title: Text(existing == null ? 'Add Expense' : 'Edit Expense'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount *'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      ...categoryOptions.map(
                        (c) => DropdownMenuItem(value: c, child: Text(c)),
                      ),
                      const DropdownMenuItem(
                        value: _addNewCategoryValue,
                        child: Text(
                          '+ Add New Category',
                          style: TextStyle(
                            color: kPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == _addNewCategoryValue) {
                        promptNewCategory();
                      } else {
                        setState(() => category = v ?? category);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date *',
                        suffixIcon: Icon(Icons.calendar_month_rounded),
                      ),
                      child: Text(fmtDate(date)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountCtrl.text.trim());
                  if (titleCtrl.text.trim().isEmpty || amount == null || amount <= 0) return;

                  if (existing == null) {
                    finance.addExpense(
                      title: titleCtrl.text.trim(),
                      amount: amount,
                      category: category,
                      date: date,
                      note: noteCtrl.text.trim().isEmpty
                          ? null
                          : noteCtrl.text.trim(),
                    );
                  } else {
                    existing.title = titleCtrl.text.trim();
                    existing.amount = amount;
                    existing.category = category;
                    existing.date = date;
                    existing.note = noteCtrl.text.trim().isEmpty
                          ? null
                          : noteCtrl.text.trim();
                    finance.updateExpense(existing);
                  }
                  Navigator.pop(ctx);
                },
                child: Text(existing == null ? 'Add' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
