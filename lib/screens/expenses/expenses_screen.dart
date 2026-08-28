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

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showExpenseDialog(context),
        child: const Icon(Icons.add),
      ),
      body: finance.expenses.isEmpty
          ? const Center(child: Text('No expenses recorded yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: finance.expenses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final e = finance.expenses[i];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0x1AE5484D),
                      child: Icon(
                        Icons.arrow_downward_rounded,
                        color: kAccentRed,
                      ),
                    ),
                    title: Text(
                      e.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('${e.category} • ${fmtDate(e.date)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fmtMoney(e.amount),
                          style: const TextStyle(
                            color: kAccentRed,
                            fontWeight: FontWeight.bold,
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
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
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

  /// Shared Add/Edit dialog. If [existing] is null, this adds a new expense;
  /// otherwise it edits the given expense in place.
  void _showExpenseDialog(BuildContext context, {Expense? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title);
    final amountCtrl = TextEditingController(
      text: existing != null ? existing.amount.toString() : '',
    );
    final noteCtrl = TextEditingController(text: existing?.note);
    final finance = context.read<FinanceProvider>();
    final settings = context.read<SettingsProvider>();

    // Ensure the expense's current category is always selectable even if
    // it was somehow removed from the category list.
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
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                  ),
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
                    initialValue: category,
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
                  if (titleCtrl.text.trim().isEmpty || amount == null) return;

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
