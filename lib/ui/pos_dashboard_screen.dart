import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../design_system/sari_design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/sarisync_blocs.dart';
import '../data/sarisync_database.dart';
import 'checkout_screen.dart';
import 'inventory_screen.dart';

class POSDashboardScreen extends StatefulWidget {
  const POSDashboardScreen({super.key});

  @override
  State<POSDashboardScreen> createState() => _POSDashboardScreenState();
}

class _POSDashboardScreenState extends State<POSDashboardScreen> {
  final TextEditingController _discountController = TextEditingController();
  List<Product> _products = [];
  bool _isLoading = true;
  StreamSubscription<List<Product>>? _productSubscription;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    context.read<AuditCubit>().loadAudit(DateTime.now());
  }

  Future<void> _loadProducts() async {
    final db = AppDatabase.instance;
    _productSubscription = db.watchInventory().listen((products) {
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _productSubscription?.cancel();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: SariColors.primaryGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                child: Image(
                  image: AssetImage('assets/sarisync.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'SariSync Dashboard',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: SariGradients.appBar,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                context.read<AuditCubit>().loadAudit(DateTime.now());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCards(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildLowStockAlerts(),
                    const SizedBox(height: 80), // Space for checkout bar
                  ],
                ),
              ),
            ),
      bottomSheet: _buildCheckoutBar(),
    );
  }

  Widget _buildSummaryCards() {
    return BlocBuilder<AuditCubit, AuditState>(
      builder: (context, state) {
        if (state is AuditLoaded) {
          final summary = state.summary;
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SariStatCard(
                      title: 'Today\'s Sales',
                      value: '₱${summary.grossRevenue.toStringAsFixed(2)}',
                      icon: Icons.point_of_sale,
                      iconColor: SariColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SariStatCard(
                      title: 'Net Margin',
                      value: '₱${summary.netMargin.toStringAsFixed(2)}',
                      icon: Icons.trending_up,
                      iconColor: SariColors.success,
                      backgroundColor: SariColors.success.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SariStatCard(
                      title: 'Debt Coll.',
                      value: '₱${summary.debtCollections.toStringAsFixed(2)}',
                      icon: Icons.payments,
                      iconColor: SariColors.accentAmber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SariStatCard(
                      title: 'Expenses',
                      value: '₱${summary.expenses.toStringAsFixed(2)}',
                      icon: Icons.money_off,
                      iconColor: SariColors.error,
                      backgroundColor: SariColors.error.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SariStatCard(
                title: 'Total Outstanding',
                value: '₱${summary.totalOutstandingDebt.toStringAsFixed(2)}',
                icon: Icons.account_balance_wallet,
                iconColor: SariColors.error,
                backgroundColor: SariColors.error.withValues(alpha: 0.1),
              ),
            ],
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SariActionButton(
                label: 'New Sale',
                icon: Icons.add_shopping_cart,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CheckoutScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SariActionButton(
                label: 'Record Expense',
                icon: Icons.receipt_long,
                isPrimary: false,
                onPressed: () {
                  _showAddExpenseDialog();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddExpenseDialog() {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SingleChildScrollView(
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
                  const Icon(Icons.receipt_long, color: SariColors.error),
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
                  labelText: 'Description',
                  hintText: 'e.g., Electricity bill, Rent, Snacks',
                  prefixIcon: Icon(Icons.description),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.money),
                  prefixText: '₱',
                ),
              ),
              const SizedBox(height: 24),
              SariActionButton(
                label: 'Save Expense',
                backgroundColor: SariColors.error,
                onPressed: () async {
                  final description = descriptionController.text.trim();
                  final amount = double.tryParse(amountController.text);

                  if (description.isEmpty || amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a description and valid amount'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  await sheetContext.read<ExpenseCubit>().addExpense(description, amount);
                  if (!sheetContext.mounted) return;
                  sheetContext.read<AuditCubit>().loadAudit(DateTime.now());
                  Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLowStockAlerts() {
    final lowStockProducts = _products.where((p) => p.stockQuantity <= p.minStockAlert).toList();
    if (lowStockProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Low Stock Alerts',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: SariColors.error),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: SariColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${lowStockProducts.length} items',
                style: const TextStyle(color: SariColors.error, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: lowStockProducts.length > 3 ? 3 : lowStockProducts.length,
          itemBuilder: (context, index) {
            final product = lowStockProducts[index];
            return SariProductTile(
              productName: product.name,
              category: product.category,
              sellingPrice: product.sellingPrice,
              costPrice: product.costPrice,
              stockQuantity: product.stockQuantity,
              minStockAlert: product.minStockAlert,
              imagePath: product.imagePath,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InventoryScreen()),
                );
              },
            );
          },
        ),
        if (lowStockProducts.length > 3)
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InventoryScreen()),
                );
              },
              child: const Text('View All Low Stock'),
            ),
          ),
      ],
    );
  }

  Widget _buildCheckoutBar() {
    return BlocConsumer<CartCubit, CartState>(
      listener: (context, state) {
        if (state is CartCheckoutSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          _discountController.clear();
          context.read<AuditCubit>().loadAudit(DateTime.now());
          context.read<DebtCubit>().refreshDebts(); // Add this
        } else if (state is CartError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final items = state is CartLoaded ? state.items : (state is CartCheckoutSuccess ? state.items : <CartItem>[]);
        if (items.isEmpty) return const SizedBox.shrink();

        final discount = state is CartLoaded ? state.discount : (state is CartCheckoutSuccess ? state.discount : 0.0);
        final subtotal = items.fold(0.0, (sum, item) => sum + item.total);
        final total = subtotal - discount;
        final itemCount = items.fold(0, (sum, item) => sum + item.quantity);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SariColors.backgroundWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: SariColors.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.shopping_cart, color: SariColors.primaryGreen),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$itemCount items',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (discount > 0)
                              Text(
                                'Subtotal: ₱${subtotal.toStringAsFixed(2)}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            Text(
                              'Total: ₱${total.toStringAsFixed(2)}',
                              style: const TextStyle(color: SariColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<CartCubit>().clearCart();
                      _discountController.clear();
                    },
                    child: const Text('Clear', style: TextStyle(color: SariColors.error)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SariActionButton(
                      label: 'Utang',
                      isPrimary: false,
                      onPressed: () => _showUtangCheckoutSheet(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SariActionButton(
                      label: 'Checkout',
                      onPressed: () => context.read<CartCubit>().checkout(paymentMethod: 'Cash'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUtangCheckoutSheet(BuildContext context) {
    final customerNameController = TextEditingController();
    final customerContactController = TextEditingController();
    DateTime? selectedDueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SingleChildScrollView(
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
                      Icon(Icons.credit_card, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'UTANG (Credit) Checkout',
                          style: Theme.of(context).textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: customerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name *',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: customerContactController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Number',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setSheetState(() {
                          selectedDueDate = date;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Due Date',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        selectedDueDate != null
                            ? '${selectedDueDate!.month}/${selectedDueDate!.day}/${selectedDueDate!.year}'
                            : 'Select due date',
                        style: TextStyle(
                          color: selectedDueDate != null ? null : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SariActionButton(
                    label: 'Confirm Credit Sale',
                    onPressed: () {
                      if (customerNameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Customer name is required'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      context.read<CartCubit>().checkout(
                            paymentMethod: 'Utang',
                            customerName: customerNameController.text.trim(),
                            customerContact: customerContactController.text.trim().isNotEmpty
                                ? customerContactController.text.trim()
                                : null,
                            dueDate: selectedDueDate,
                          );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}