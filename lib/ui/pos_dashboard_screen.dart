import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../design_system/sari_design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/sarisync_blocs.dart';
import '../data/sarisync_database.dart';

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
            const Text('SariSync'),
          ],
        ),
        centerTitle: false,
        backgroundColor: SariColors.backgroundWhite,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: _buildProductGrid()),
                _buildCheckoutBar(),
              ],
            ),
    );
  }

  Widget _buildProductGrid() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Products',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.9,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              final isLowStock = product.stockQuantity <= product.minStockAlert;
              return _buildProductCard(product, isLowStock);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product, bool isLowStock) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isLowStock ? Colors.red.shade300 : Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        onTap: () {
          if (product.stockQuantity > 0) {
            context.read<CartCubit>().addToCart(product);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: product.imagePath != null && File(product.imagePath!).existsSync()
                    ? Image.file(
                        File(product.imagePath!),
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: const Color(0xFFF5F7FA),
                        child: Icon(
                          Icons.inventory_2,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                      ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '₱${product.sellingPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isLowStock 
                                ? (product.stockQuantity == 0 ? Colors.red.shade100 : Colors.orange.shade100)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${product.stockQuantity}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isLowStock 
                                  ? (product.stockQuantity == 0 ? Colors.red.shade700 : Colors.orange.shade700)
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutBar() {
    return BlocConsumer<CartCubit, CartState>(
      listener: (context, state) {
        if (state is CartSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          _discountController.clear();
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
        final items = state is CartLoaded ? state.items : <CartItem>[];
        final discount = state is CartLoaded ? state.discount : 0.0;
        final subtotal = items.fold(0.0, (sum, item) => sum + item.total);
        final total = subtotal - discount;
        final itemCount = items.fold(0, (sum, item) => sum + item.quantity);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Cart Icon and Item Count
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.white, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '$itemCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Price Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Subtotal: ₱${subtotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Total: ₱${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (items.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          context.read<CartCubit>().clearCart();
                          _discountController.clear();
                        },
                        icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: items.isEmpty
                          ? null
                          : () => _showCheckoutSheet(context, 'Cash'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        minimumSize: const Size(0, 40),
                      ),
                      child: const Text('Checkout', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCheckoutSheet(BuildContext context, String paymentMethod) {
    if (paymentMethod == 'Utang') {
      _showUtangCheckoutSheet(context);
    } else {
      context.read<CartCubit>().checkout(paymentMethod: 'Cash');
    }
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
                      Icon(Icons.credit_card, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'UTANG (Credit) Checkout',
                        style: Theme.of(context).textTheme.titleLarge,
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
                  ElevatedButton.icon(
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
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm Credit Sale'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
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