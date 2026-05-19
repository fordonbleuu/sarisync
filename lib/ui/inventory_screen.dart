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
          _isLoading = false;
        });
      }
    });
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
    final totalValue = _products.fold<double>(0, (sum, p) => sum + (p.costPrice * p.stockQuantity));

    return SizedBox(
      height: 130,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Expanded(
            child: SariStatCard(
              title: 'Total Products',
              value: '$totalProducts',
              icon: Icons.inventory_2,
              iconColor: SariColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SariStatCard(
              title: 'Total Stock',
              value: '$totalStock',
              icon: Icons.widgets,
              iconColor: SariColors.secondaryNavy,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SariStatCard(
              title: 'Out of Stock',
              value: '$outOfStock',
              icon: Icons.remove_shopping_cart,
              iconColor: SariColors.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SariStatCard(
              title: 'Inventory Value',
              value: '₱${totalValue.toStringAsFixed(0)}',
              icon: Icons.attach_money,
              iconColor: SariColors.success,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        centerTitle: true,
        backgroundColor: SariColors.backgroundWhite,
        surfaceTintColor: Colors.transparent,
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'No products found',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () => _showProductFormSheet(context),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Product'),
                              ),
                            ],
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isLowStock ? Colors.red.shade300 : Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 70,
                height: 70,
                child: product.imagePath != null && File(product.imagePath!).existsSync()
                    ? Image.file(File(product.imagePath!), fit: BoxFit.cover)
                    : Container(
                        color: SariColors.backgroundLight,
                        child: Icon(Icons.inventory_2, color: Colors.grey.shade400),
                      ),
              ),
            ),
            const SizedBox(width: 16),
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
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isLowStock)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: product.stockQuantity == 0 
                                ? Colors.red.shade100 
                                : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.stockQuantity == 0 ? 'OUT' : 'LOW',
                            style: TextStyle(
                              color: product.stockQuantity == 0 
                                  ? Colors.red.shade700 
                                  : Colors.orange.shade700,
                              fontSize: 11,
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
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPriceTag('Cost', product.costPrice),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _buildPriceTag('Sell', product.sellingPrice, isPrimary: true),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: SariColors.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${product.stockQuantity}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: SariColors.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton(
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
        color: isPrimary ? Theme.of(context).colorScheme.primaryContainer : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: ₱${price.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
          color: isPrimary ? Theme.of(context).colorScheme.onPrimaryContainer : Colors.grey.shade700,
        ),
        overflow: TextOverflow.ellipsis,
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
          ElevatedButton(
            onPressed: () {
              context.read<InventoryBloc>().add(DeleteProduct(product));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
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
    final costPriceController = TextEditingController(text: product?.costPrice.toString() ?? '');
    final sellingPriceController = TextEditingController(text: product?.sellingPrice.toString() ?? '');
    final stockController = TextEditingController(text: product?.stockQuantity.toString() ?? '0');
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
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: costPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Cost Price *',
                            prefixIcon: Icon(Icons.attach_money),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: sellingPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Selling Price *',
                            prefixIcon: Icon(Icons.sell),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: stockController,
                          decoration: const InputDecoration(
                            labelText: 'Stock Quantity *',
                            prefixIcon: Icon(Icons.inventory),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: minStockController,
                          decoration: const InputDecoration(
                            labelText: 'Min Stock Alert',
                            prefixIcon: Icon(Icons.warning),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      final name = nameController.text.trim();
                      final category = categoryController.text.trim();
                      final costPrice = double.tryParse(costPriceController.text);
                      final sellingPrice = double.tryParse(sellingPriceController.text);
                      final stock = int.tryParse(stockController.text);
                      final minStock = int.tryParse(minStockController.text) ?? 5;

                      if (name.isEmpty || category.isEmpty || costPrice == null || sellingPrice == null || stock == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all required fields'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (isEditing) {
                        final updatedProduct = Product(
                          id: product.id,
                          name: name,
                          barCode: barcodeController.text.trim().isNotEmpty ? barcodeController.text.trim() : null,
                          category: category,
                          costPrice: costPrice,
                          sellingPrice: sellingPrice,
                          stockQuantity: stock,
                          minStockAlert: minStock,
                          imagePath: imagePath,
                        );
                        context.read<InventoryBloc>().add(UpdateProduct(updatedProduct));
                      } else {
                        context.read<InventoryBloc>().add(AddProduct(
                              name: name,
                              category: category,
                              costPrice: costPrice,
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