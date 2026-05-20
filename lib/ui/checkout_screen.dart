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
  final Map<String, int> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
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

  void _addItem(Product product) {
    setState(() {
      _selectedItems[product.id] = (_selectedItems[product.id] ?? 0) + 1;
    });
  }

  void _removeItem(Product product) {
    setState(() {
      final currentQty = _selectedItems[product.id] ?? 0;
      if (currentQty > 0) {
        _selectedItems[product.id] = currentQty - 1;
        if (_selectedItems[product.id] == 0) {
          _selectedItems.remove(product.id);
        }
      }
    });
  }

  void _updateQuantity(Product product, int quantity) {
    setState(() {
      if (quantity > 0) {
        _selectedItems[product.id] = quantity;
      } else {
        _selectedItems.remove(product.id);
      }
    });
  }

  double _calculateSubtotal() {
    double total = 0;
    _selectedItems.forEach((productId, qty) {
      final product = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => Product(
          id: productId,
          name: '',
          category: '',
          costPrice: 0,
          sellingPrice: 0,
          stockQuantity: 0,
        ),
      );
      total += product.sellingPrice * qty;
    });
    return total;
  }

  List<MapEntry<Product, int>> get _cartItems {
    final entries = <MapEntry<Product, int>>[];
    _selectedItems.forEach((productId, qty) {
      final product = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => Product(
          id: productId,
          name: '',
          category: '',
          costPrice: 0,
          sellingPrice: 0,
          stockQuantity: 0,
        ),
      );
      if (product.name.isNotEmpty) {
        entries.add(MapEntry(product, qty));
      }
    });
    return entries;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = _calculateSubtotal();
    final discount = double.tryParse(_discountController.text) ?? 0.0;
    final total = subtotal - discount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
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
                                  final selectedQty = _selectedItems[product.id] ?? 0;
                                  return _buildProductItem(product, selectedQty);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  color: Theme.of(context).dividerColor,
                ),
                Expanded(
                  flex: 1,
                  child: _buildCartPane(subtotal, discount, total),
                ),
              ],
            ),
    );
  }

  Widget _buildProductItem(Product product, int selectedQty) {
    final isLowStock = product.stockQuantity <= product.minStockAlert;
    final isOutOfStock = product.stockQuantity == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
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
                        color: SariColors.backgroundLight,
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
                      Text(
                        '₱${product.sellingPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
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
                if (newQty > selectedQty) {
                  _addItem(product);
                } else {
                  _removeItem(product);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartPane(double subtotal, double discount, double total) {
    final cartItems = _cartItems;

    return BlocConsumer<CartCubit, CartState>(
      listener: (context, state) {
        if (state is CartSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          _selectedItems.clear();
          _discountController.clear();
          Navigator.pop(context);
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
              decoration: BoxDecoration(
                color: SariColors.primaryGreen,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Cart (${cartItems.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
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
                        final entry = cartItems[index];
                        return _buildCartItem(entry.key, entry.value);
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Subtotal: '),
                      Text(
                        '₱${subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Discount: '),
                      Expanded(
                        child: TextField(
                          controller: _discountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₱${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: cartItems.isEmpty ? null : () => _checkout('Cash'),
                          icon: const Icon(Icons.money),
                          label: const Text('Cash'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: cartItems.isEmpty ? null : () => _showUtangDialog(),
                          icon: const Icon(Icons.credit_card),
                          label: const Text('Utang'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
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
                          setState(() {
                            _selectedItems.clear();
                            _discountController.clear();
                          });
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
            const SizedBox(width: 4),
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
            const SizedBox(width: 4),
            StockAwareQuantityInput(
              quantity: quantity,
              maxStock: product.stockQuantity,
              onChanged: (newQty) => _updateQuantity(product, newQty),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 16, color: Colors.red),
              onPressed: () => _updateQuantity(product, 0),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  void _checkout(String paymentMethod) {
    final cartItems = _cartItems;
    if (cartItems.isEmpty) return;

    context.read<CartCubit>().clearCart();
    for (final entry in cartItems) {
      context.read<CartCubit>().addToCartWithQuantity(entry.key, entry.value);
    }

    final discount = double.tryParse(_discountController.text) ?? 0.0;
    context.read<CartCubit>().setDiscount(discount);
    context.read<CartCubit>().checkout(paymentMethod: paymentMethod);
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

                      final cartItems = _cartItems;
                      if (cartItems.isEmpty) return;

                      context.read<CartCubit>().clearCart();
                      for (final entry in cartItems) {
                        context.read<CartCubit>().addToCartWithQuantity(entry.key, entry.value);
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