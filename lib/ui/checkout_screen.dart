import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/sarisync_blocs.dart';
import '../data/sarisync_database.dart';
import '../design_system/sari_design_system.dart';
import 'widgets/stock_aware_quantity_spinner.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    // Initialize discount controller from current cart state
    final cartCubit = context.read<CartCubit>();
    if (cartCubit.state is CartLoaded) {
      final discount = (cartCubit.state as CartLoaded).discount;
      if (discount > 0) {
        _discountController.text = discount.toString();
      }
    }
  }

  void _loadProducts() {
    AppDatabase.instance.watchInventory().listen((products) {
      if (mounted) {
        setState(() {
          _products = products;
          _filteredProducts = products;
          _isLoading = false;
        });
      }
    });
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((p) {
          return p.name.toLowerCase().contains(query.toLowerCase()) ||
              (p.barCode?.toLowerCase().contains(query.toLowerCase()) ?? false);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        final items = cartState is CartLoaded ? cartState.items : <CartItem>[];
        final subtotal = items.fold(0.0, (sum, item) => sum + (item.product.sellingPrice * item.quantity));
        final discount = cartState is CartLoaded ? cartState.discount : 0.0;
        final total = subtotal - discount;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Checkout'),
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: SariGradients.appBar,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;

                    if (isMobile) {
                      return Column(
                        children: [
                          Expanded(
                            child: _buildProductListSection(),
                          ),
                          SizedBox(
                            height: 1,
                            child: ColoredBox(color: Theme.of(context).dividerColor),
                          ),
                          _buildMobileCartSummary(items, subtotal, discount, total),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildProductListSection(),
                        ),
                        const SizedBox(
                          width: 1,
                        ),
                        Expanded(
                          flex: 1,
                          child: _buildCartPane(items, subtotal, discount, total),
                        ),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildProductListSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products by name or barcode...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _filterProducts,
          ),
        ),
        Expanded(
          child: _filteredProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'No products found',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    final cartItems = context.read<CartCubit>().state is CartLoaded
                        ? (context.read<CartCubit>().state as CartLoaded).items
                        : <CartItem>[];
                    final cartItem = cartItems.firstWhere(
                      (item) => item.product.id == product.id,
                      orElse: () => CartItem(product: product, quantity: 0),
                    );
                    return _buildProductItem(product, cartItem.quantity);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMobileCartSummary(List<CartItem> items, double subtotal, double discount, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SariColors.backgroundWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              Text('${items.length} items selected', style: const TextStyle(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => _showMobileCartDetails(items, subtotal, discount, total),
                child: const Text('View Cart'),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ₱${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: SariColors.primaryGreen),
              ),
              ElevatedButton(
                onPressed: items.isEmpty ? null : () => _showMobileCartDetails(items, subtotal, discount, total),
                child: const Text('Checkout'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMobileCartDetails(List<CartItem> items, double subtotal, double discount, double total) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
  return SizedBox(
    height: MediaQuery.of(context).size.height * 0.85,
    child: _buildCartPane(items, subtotal, discount, total),
  );
},
    );
  }

  Widget _buildProductItem(Product product, int selectedQty) {
    final isLowStock = product.stockQuantity <= product.minStockAlert;
    final isOutOfStock = product.stockQuantity == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: SariGradients.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SariColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 50,
                height: 50,
                child: product.imagePath != null && File(product.imagePath!).existsSync()
                    ? Image.file(File(product.imagePath!), fit: BoxFit.cover)
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [SariColors.backgroundLight, Color(0xFFE8F0FE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(Icons.inventory_2, color: Colors.grey.shade400, size: 24),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '₱${product.sellingPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOutOfStock
                              ? Colors.red.shade100
                              : (isLowStock ? Colors.orange.shade100 : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${product.stockQuantity}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isOutOfStock
                                ? Colors.red.shade700
                                : (isLowStock ? Colors.orange.shade700 : Colors.grey.shade700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            StockAwareQuantitySpinner(
              quantity: selectedQty,
              maxStock: product.stockQuantity,
              enabled: !isOutOfStock,
              onChanged: (newQty) {
                context.read<CartCubit>().updateQuantity(product.id, newQty, product: product);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartPane(List<CartItem> cartItems, double subtotal, double discount, double total) {
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
          if (Navigator.of(context).canPop()) {
            Navigator.pop(context);
          }
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
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: SariGradients.primaryHorizontal,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Cart (${cartItems.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            // "Reflect" Dashboard metrics here
            BlocBuilder<AuditCubit, AuditState>(
              builder: (context, auditState) {
                if (auditState is AuditLoaded) {
                  return Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: SariColors.primaryGreen.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: SariColors.primaryGreen.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Today\'s Sales:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: SariColors.textSecondary),
                        ),
                        Text(
                          '₱${auditState.summary.grossRevenue.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: SariColors.primaryGreen),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            Expanded(
              child: cartItems.isEmpty
                  ? const Center(
                      child: Text(
                        'No items selected',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return _buildCartItem(item.product, item.quantity);
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal',
                        style: TextStyle(fontWeight: FontWeight.w500, color: SariColors.textSecondary),
                      ),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerEnd,
                          child: Text(
                            '₱${subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Discount',
                        style: TextStyle(fontWeight: FontWeight.w500, color: SariColors.textSecondary),
                      ),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _discountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          onChanged: (value) {
                            final d = double.tryParse(value) ?? 0.0;
                            context.read<CartCubit>().setDiscount(d);
                          },
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Payable',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerEnd,
                          child: Text(
                            '₱${total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: SariGradients.buttonSuccess,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: cartItems.isEmpty ? null : () => _checkout('Cash'),
                            icon: const Icon(Icons.money),
                            label: const Text('Cash'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: SariGradients.buttonWarning,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: cartItems.isEmpty ? null : () => _showUtangDialog(),
                            icon: const Icon(Icons.credit_card),
                            label: const Text('Utang'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (cartItems.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          context.read<CartCubit>().clearCart();
                          _discountController.clear();
                        },
                        child: const Text('Clear Cart'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCartItem(Product product, int quantity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: SariGradients.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SariColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '₱${product.sellingPrice.toStringAsFixed(2)} x $quantity',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  '₱${(product.sellingPrice * quantity).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 8),
            StockAwareQuantityInput(
              quantity: quantity,
              maxStock: product.stockQuantity,
              onChanged: (newQty) => context.read<CartCubit>().updateQuantity(product.id, newQty, product: product),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 16, color: Colors.red),
              onPressed: () => context.read<CartCubit>().removeFromCart(product.id),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkout(String paymentMethod) async {
    final discount = double.tryParse(_discountController.text) ?? 0.0;
    context.read<CartCubit>().setDiscount(discount);
    await context.read<CartCubit>().checkout(paymentMethod: paymentMethod);
  }

  void _showUtangDialog() {
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
                  Container(
                    decoration: BoxDecoration(
                      gradient: SariGradients.buttonWarning,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
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

                        final discount = double.tryParse(_discountController.text) ?? 0.0;
                        context.read<CartCubit>().setDiscount(discount);
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
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
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
