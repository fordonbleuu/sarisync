import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/sarisync_blocs.dart';
import '../data/sarisync_database.dart';
import '../design_system/sari_design_system.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Product> _products = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  StreamSubscription<List<Product>>? _productSubscription;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    _productSubscription = AppDatabase.instance.watchInventory().listen((products) {
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
    super.dispose();
  }

  List<String> get _categories {
    final cats = _products.map((p) => p.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  List<Product> get _filteredProducts {
    return _products.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.barCode?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Widget _buildStatsRow() {
    final totalProducts = _products.length;
    final totalStock = _products.fold<int>(0, (sum, p) => sum + p.stockQuantity);
    final outOfStock = _products.where((p) => p.stockQuantity == 0).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildStatItem('Total Products', '$totalProducts', Icons.inventory_2, SariColors.primaryGreen),
          _buildStatItem('Total Stock', '$totalStock', Icons.widgets, SariColors.secondaryNavy),
          _buildStatItem('Out of Stock', '$outOfStock', Icons.remove_shopping_cart, SariColors.error),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 24) / 2; // Default to 2 columns
        return SizedBox(
          width: constraints.maxWidth > 500 ? (constraints.maxWidth - 24) / 3 : width,
          child: SariStatCard(
            title: title,
            value: value,
            icon: icon,
            iconColor: color,
            useGradient: true,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: SariGradients.appBar,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SariColors.primaryGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
              onPressed: () => _showProductFormSheet(context),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 8),
                _buildStatsRow(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: _selectedCategory,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: _categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(cat, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value ?? 'All';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'No products found',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: SariGradients.buttonPrimary,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: SariColors.primaryGreen.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showProductFormSheet(context),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Product'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shadowColor: Colors.transparent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return _buildProductListItem(product);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildProductListItem(Product product) {
    final isLowStock = product.stockQuantity <= product.minStockAlert;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: SariGradients.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLowStock
              ? (product.stockQuantity == 0 ? Colors.red.shade300 : Colors.orange.shade300)
              : SariColors.divider,
          width: isLowStock ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 60,
                height: 60,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (isLowStock)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: product.stockQuantity == 0
                                ? SariGradients.error
                                : SariGradients.buttonWarning,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.stockQuantity == 0 ? 'OUT' : 'LOW',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildPriceTag('Sell', product.sellingPrice, isPrimary: true),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: SariColors.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Stock: ${product.stockQuantity}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: SariColors.primaryGreen,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton(
              padding: EdgeInsets.zero,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showProductFormSheet(context, product: product);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(context, product);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceTag(String label, double price, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                colors: [
                  SariColors.primaryGreen.withValues(alpha: 0.1),
                  SariColors.primaryGreenDark.withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : SariGradients.cardSubtle,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$label: ₱${price.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
            color: isPrimary ? SariColors.primaryGreen : Colors.grey.shade700,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: SariGradients.buttonError,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () {
                context.read<InventoryBloc>().add(DeleteProduct(product));
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
              ),
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductFormSheet(BuildContext context, {Product? product}) {
    final isEditing = product != null;
    final nameController = TextEditingController(text: product?.name ?? '');
    final barcodeController = TextEditingController(text: product?.barCode ?? '');
    final categoryController = TextEditingController(text: product?.category ?? '');
    final sellingPriceController = TextEditingController(text: product?.sellingPrice.toString() ?? '');
    final stockController = TextEditingController(text: !isEditing ? (product?.stockQuantity.toString() ?? '0') : '');
    final addStockController = isEditing ? TextEditingController() : null;
    final minStockController = TextEditingController(text: product?.minStockAlert.toString() ?? '5');
    String? imagePath = product?.imagePath;

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
                      Icon(isEditing ? Icons.edit : Icons.add_box, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        isEditing ? 'Edit Product' : 'Add New Product',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: GestureDetector(
                      onTap: () => _showImagePickerSheet(sheetContext, (path) {
                        setSheetState(() {
                          imagePath = path;
                        });
                      }),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: imagePath != null && File(imagePath!).existsSync()
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(imagePath!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, size: 32, color: Colors.grey.shade500),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Add Photo',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name *',
                      prefixIcon: Icon(Icons.label),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: barcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Barcode (Optional)',
                      prefixIcon: Icon(Icons.qr_code),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: categoryController.text.isEmpty ? null : categoryController.text,
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Food', child: Text('Food')),
                      DropdownMenuItem(value: 'Beverages', child: Text('Beverages')),
                      DropdownMenuItem(value: 'Snacks', child: Text('Snacks')),
                      DropdownMenuItem(value: 'Personal Care', child: Text('Personal Care')),
                      DropdownMenuItem(value: 'Household Supplies', child: Text('Household Supplies')),
                      DropdownMenuItem(value: 'Cleaning Products', child: Text('Cleaning Products')),
                      DropdownMenuItem(value: 'Health Products', child: Text('Health Products')),
                      DropdownMenuItem(value: 'Baby Products', child: Text('Baby Products')),
                      DropdownMenuItem(value: 'School Supplies', child: Text('School Supplies')),
                      DropdownMenuItem(value: 'Mobile & Digital Services', child: Text('Mobile & Digital Services')),
                      DropdownMenuItem(value: 'Frozen Goods', child: Text('Frozen Goods')),
                      DropdownMenuItem(value: 'Tobacco Products', child: Text('Tobacco Products')),
                      DropdownMenuItem(value: 'Pet Supplies', child: Text('Pet Supplies')),
                      DropdownMenuItem(value: 'Kitchen Essentials', child: Text('Kitchen Essentials')),
                      DropdownMenuItem(value: 'Hardware Items', child: Text('Hardware Items')),
                      DropdownMenuItem(value: 'Clothing & Accessories', child: Text('Clothing & Accessories')),
                      DropdownMenuItem(value: 'Toys & Miscellaneous', child: Text('Toys & Miscellaneous')),
                      DropdownMenuItem(value: 'Others', child: Text('Others')),
                    ],
                    onChanged: (value) {
                      categoryController.text = value ?? '';
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: sellingPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Selling Price *',
                      prefixIcon: Icon(Icons.sell),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  if (isEditing) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const                           Icon(Icons.inventory, color: Colors.grey),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              'Current Stock: ',
                              style: TextStyle(color: Colors.grey.shade700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${product.stockQuantity}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addStockController,
                      decoration: const InputDecoration(
                        labelText: 'Stock to Add',
                        prefixIcon: Icon(Icons.add_box),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ] else ...[
                    TextField(
                      controller: stockController,
                      decoration: const InputDecoration(
                        labelText: 'Stock Quantity *',
                        prefixIcon: Icon(Icons.inventory),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: minStockController,
                    decoration: const InputDecoration(
                      labelText: 'Min Stock Alert',
                      prefixIcon: Icon(Icons.warning),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      gradient: SariGradients.buttonPrimary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: SariColors.primaryGreen.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final name = nameController.text.trim();
                        final category = categoryController.text.trim();
                        final sellingPrice = double.tryParse(sellingPriceController.text);
                        final stock = int.tryParse(stockController.text);
                        final addStock = int.tryParse(addStockController?.text ?? '');
                        final minStock = int.tryParse(minStockController.text) ?? 5;

                        if (name.isEmpty || category.isEmpty || sellingPrice == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill all required fields'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (isEditing) {
                          if (addStock == null || addStock <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a valid stock amount to add'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          final updatedProduct = Product(
                            id: product.id,
                            name: name,
                            barCode: barcodeController.text.trim().isNotEmpty ? barcodeController.text.trim() : null,
                            category: category,
                            costPrice: product.costPrice,
                            sellingPrice: sellingPrice,
                            stockQuantity: product.stockQuantity + addStock,
                            minStockAlert: minStock,
                            imagePath: imagePath,
                          );
                          context.read<InventoryBloc>().add(UpdateProduct(updatedProduct));
                        } else {
                          if (stock == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all required fields'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          context.read<InventoryBloc>().add(AddProduct(
                                name: name,
                                category: category,
                                costPrice: 0,
                                sellingPrice: sellingPrice,
                                stockQuantity: stock,
                                minStockAlert: minStock,
                                barCode: barcodeController.text.trim().isNotEmpty ? barcodeController.text.trim() : null,
                                imagePath: imagePath,
                              ));
                        }
                        Navigator.pop(context);
                      },
                      icon: Icon(isEditing ? Icons.save : Icons.add),
                      label: Text(isEditing ? 'Save Changes' : 'Add Product'),
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

  void _showImagePickerSheet(BuildContext parentContext, Function(String?) onImageSelected) {
    showModalBottomSheet(
      context: parentContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final path = await ImageHelper.captureAndSaveImage();
                  onImageSelected(path);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final path = await ImageHelper.pickFromGallery();
                  onImageSelected(path);
                },
              ),
              ListTile(
                    leading: const Icon(Icons.cancel),
                    title: const Text('Cancel'),
                    onTap: () => Navigator.pop(ctx),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}