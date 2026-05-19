part of 'sarisync_blocs.dart';

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadInventory extends InventoryEvent {}

class InventoryUpdated extends InventoryEvent {
  final List<Product> products;

  const InventoryUpdated(this.products);

  @override
  List<Object?> get props => [products];
}

class AddProduct extends InventoryEvent {
  final String name;
  final String category;
  final double costPrice;
  final double sellingPrice;
  final int stockQuantity;
  final int minStockAlert;
  final String? barCode;
  final String? imagePath;

  const AddProduct({
    required this.name,
    required this.category,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQuantity,
    this.minStockAlert = 5,
    this.barCode,
    this.imagePath,
  });

  @override
  List<Object?> get props => [name, category, costPrice, sellingPrice, stockQuantity, minStockAlert, barCode, imagePath];
}

class UpdateProduct extends InventoryEvent {
  final Product product;

  const UpdateProduct(this.product);

  @override
  List<Object?> get props => [product];
}

class DeleteProduct extends InventoryEvent {
  final Product product;

  const DeleteProduct(this.product);

  @override
  List<Object?> get props => [product];
}