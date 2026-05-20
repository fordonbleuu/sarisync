import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/sarisync_database.dart';
import '../design_system/sari_design_system.dart';

class AuditReportScreen extends StatefulWidget {
  const AuditReportScreen({super.key});

  @override
  State<AuditReportScreen> createState() => _AuditReportScreenState();
}

class _AuditReportScreenState extends State<AuditReportScreen> {
  DateTime _selectedDate = DateTime.now();
  DailyFinancialSummary? _summary;
  bool _isLoading = true;
  List<SalesItem> _salesItems = [];
  Map<String, Product> _productMap = {};

  @override
  void initState() {
    super.initState();
    _loadAuditData();
  }

  Future<void> _loadAuditData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final summary = await AppDatabase.instance.computeAuditedMetricsForDate(_selectedDate);
      final items = await AppDatabase.instance.getSalesItemsForDate(_selectedDate);
      final products = await AppDatabase.instance.getProductsForItems(items);
      final productMap = <String, Product>{};
      for (final p in products) {
        productMap[p.id] = p;
      }
      setState(() {
        _summary = summary;
        _salesItems = items;
        _productMap = productMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadAuditData();
  }

  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
    });
    _loadAuditData();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
      _loadAuditData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Report'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.today, color: Color(0xFF1565C0)),
            ),
            onPressed: _goToToday,
            tooltip: 'Go to Today',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildDateNavigation(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildSummaryGrid(),
                        const SizedBox(height: 24),
                        _buildNetMarginCard(),
                        const SizedBox(height: 24),
                        _buildExpenseSection(),
                        const SizedBox(height: 24),
                        _buildItemsSoldSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseSheet(context),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Add Expense'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildDateNavigation() {
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _navigateDate(-1),
          ),
          Expanded(
            child: InkWell(
              onTap: _selectDate,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isToday
                            ? 'Today'
                            : DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: isToday ? null : () => _navigateDate(1),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid() {
    if (_summary == null) {
      return const Center(child: Text('No data available'));
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: SariStatCard(
              title: 'Gross Revenue',
              value: '₱${_summary!.grossRevenue.toStringAsFixed(2)}',
              icon: Icons.trending_up,
              iconColor: SariColors.success,
            )),
            const SizedBox(width: 12),
            Expanded(child: SariStatCard(
              title: 'COGS',
              value: '₱${_summary!.cogs.toStringAsFixed(2)}',
              icon: Icons.account_balance_wallet,
              iconColor: SariColors.warning,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: SariStatCard(
              title: 'Gross Profit',
              value: '₱${(_summary!.grossRevenue - _summary!.cogs).toStringAsFixed(2)}',
              icon: Icons.trending_up,
              iconColor: SariColors.success,
            )),
            const SizedBox(width: 12),
            Expanded(child: SariStatCard(
              title: 'Expenses',
              value: '₱${_summary!.expenses.toStringAsFixed(2)}',
              icon: Icons.money_off,
              iconColor: SariColors.error,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: SariStatCard(
              title: 'Net Profit',
              value: '₱${_summary!.netMargin.toStringAsFixed(2)}',
              icon: Icons.account_balance,
              iconColor: _summary!.netMargin >= 0 ? SariColors.primaryGreen : SariColors.error,
              backgroundColor: _summary!.netMargin >= 0 
                  ? SariColors.primaryGreen.withValues(alpha: 0.1) 
                  : SariColors.error.withValues(alpha: 0.1),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildNetMarginCard() {
    if (_summary == null) return const SizedBox.shrink();

    final marginPercent = _summary!.grossRevenue > 0
        ? (_summary!.netMargin / _summary!.grossRevenue * 100)
        : 0.0;
    final isPositive = _summary!.netMargin >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [Colors.green.shade600, Colors.green.shade400]
              : [Colors.purple.shade600, Colors.purple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            isPositive ? 'PROFIT' : 'LOSS',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₱${_summary!.netMargin.abs().toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${marginPercent.abs().toStringAsFixed(1)}% margin',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMiniStat('Revenue', _summary!.grossRevenue),
                Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(horizontal: 16)),
                _buildMiniStat('COGS', _summary!.cogs),
                Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(horizontal: 16)),
                _buildMiniStat('Expenses', _summary!.expenses),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, double value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
        Text(
          '₱${value.toStringAsFixed(0)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Expense Types',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildExpenseChip('Rent', Icons.home),
            _buildExpenseChip('Electric', Icons.bolt),
            _buildExpenseChip('Water', Icons.water_drop),
            _buildExpenseChip('Salary', Icons.people),
            _buildExpenseChip('Supplies', Icons.inventory),
            _buildExpenseChip('Transport', Icons.directions_bus),
            _buildExpenseChip('Maintenance', Icons.build),
            _buildExpenseChip('Other', Icons.more_horiz),
          ],
        ),
      ],
    );
  }

  Widget _buildExpenseChip(String label, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () => _showAddExpenseSheet(context, presetType: label),
    );
  }

  Widget _buildItemsSoldSection() {
    if (_salesItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No items sold today',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final itemGroups = <String, int>{};
    for (final item in _salesItems) {
      final product = _productMap[item.productId];
      final name = product?.name ?? 'Unknown';
      itemGroups[name] = (itemGroups[name] ?? 0) + item.quantity;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shopping_bag, color: Color(0xFF1565C0)),
              SizedBox(width: 8),
              Text(
                'Things Bought',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...itemGroups.entries.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.key),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'x${entry.value}',
                    style: const TextStyle(
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _showAddExpenseSheet(BuildContext context, {String? presetType}) {
    final descriptionController = TextEditingController(text: presetType ?? '');
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.money_off, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Record Expense',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Electric bill, Employee salary',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Amount *',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                  hintText: '0.00',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final description = descriptionController.text.trim();
                  final amount = double.tryParse(amountController.text);

                  if (description.isEmpty) {
                    if (sheetContext.mounted) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a description'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }

                  if (amount == null || amount <= 0) {
                    if (sheetContext.mounted) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid amount'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }

                  await AppDatabase.instance.addExpense(
                    description: description,
                    amount: amount,
                  );

                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                  }
                  _loadAuditData();

                  if (sheetContext.mounted) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      SnackBar(
                        content: Text('Expense of ₱${amount.toStringAsFixed(2)} recorded'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Expense'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}