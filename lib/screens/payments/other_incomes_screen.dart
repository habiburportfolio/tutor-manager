import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/other_income.dart';
import '../../providers/finance_provider.dart';
import '../../utils/theme.dart';
import '../../utils/formatters.dart';

const List<String> _kOtherIncomeCategories = [
  'Admission Fee',
  'Book / Sheet',
  'Exam Fee',
  'Batch / Special Class',
  'Donation / Gift',
  'Rental / Lab',
  'Other',
];

class OtherIncomesScreen extends StatefulWidget {
  const OtherIncomesScreen({super.key});

  @override
  State<OtherIncomesScreen> createState() => _OtherIncomesScreenState();
}

class _OtherIncomesScreenState extends State<OtherIncomesScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();

    final filtered = finance.otherIncomes.where((o) {
      if (_selectedCategory != 'All' &&
          o.category.toLowerCase() != _selectedCategory.toLowerCase()) {
        return false;
      }
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return o.title.toLowerCase().contains(q) ||
          o.category.toLowerCase().contains(q) ||
          o.receiptNo.toLowerCase().contains(q) ||
          (o.note ?? '').toLowerCase().contains(q);
    }).toList();

    final totalAmount = filtered.fold<double>(0.0, (sum, o) => sum + o.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Other Income (অন্যান্য আয়)'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Income'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Other Income',
                      style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      fmtMoney(totalAmount),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kAccentGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search other incomes...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _categoryChip('All'),
                      ..._kOtherIncomeCategories.map(_categoryChip),
                    ],
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
                        Icon(Icons.monetization_on_outlined, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No other income records found.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showAddEditDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Income'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final item = filtered[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: kAccentGreen.withValues(alpha: 0.15),
                            child: const Icon(
                              Icons.arrow_upward_rounded,
                              color: kAccentGreen,
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${item.category} • ${item.method} • ${fmtDate(item.date)}'),
                              if (item.note != null && item.note!.isNotEmpty)
                                Text(
                                  'Note: ${item.note}',
                                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                fmtMoney(item.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: kAccentGreen,
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') {
                                    _showAddEditDialog(context, existing: item);
                                  } else if (v == 'delete') {
                                    _confirmDelete(context, finance, item.id);
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
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String cat) {
    final isSelected = _selectedCategory.toLowerCase() == cat.toLowerCase();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(cat, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
        selected: isSelected,
        selectedColor: kPrimary,
        onSelected: (_) => setState(() => _selectedCategory = cat),
      ),
    );
  }

  void _confirmDelete(BuildContext context, FinanceProvider finance, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Other Income?'),
        content: const Text('Are you sure you want to delete this income record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              finance.deleteOtherIncome(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: kAccentRed)),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {OtherIncome? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title);
    final amountCtrl = TextEditingController(
      text: existing != null ? existing.amount.toString() : '',
    );
    final noteCtrl = TextEditingController(text: existing?.note);
    String category = existing?.category ?? _kOtherIncomeCategories.first;
    String method = existing?.method ?? 'Cash';
    DateTime date = existing?.date ?? DateTime.now();
    final finance = context.read<FinanceProvider>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> pickDate() async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: date,
              firstDate: DateTime(2015),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => date = picked);
          }

          return AlertDialog(
            title: Text(existing == null ? 'Add Other Income' : 'Edit Other Income'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Title / Description *',
                      hintText: 'e.g. Sheet Sale, Admission Fee',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount (৳) *'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: _kOtherIncomeCategories
                        .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => category = v ?? category),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: method,
                    decoration: const InputDecoration(labelText: 'Payment Method'),
                    items: ['Cash', 'bKash', 'Nagad', 'Rocket', 'Bank / Card', 'Online']
                        .map((m) => DropdownMenuItem<String>(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setState(() => method = v ?? method),
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
                    decoration: const InputDecoration(labelText: 'Note (optional)'),
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
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty || amount == null || amount <= 0) return;

                  if (existing == null) {
                    finance.addOtherIncome(
                      title: title,
                      amount: amount,
                      category: category,
                      method: method,
                      date: date,
                      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                    );
                  } else {
                    existing.title = title;
                    existing.amount = amount;
                    existing.category = category;
                    existing.method = method;
                    existing.date = date;
                    existing.note = noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim();
                    finance.updateOtherIncome(existing);
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
