import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;
import '../data/sarisync_database.dart';

part 'sarisync_blocs_event.dart';
part 'sarisync_blocs_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final AppDatabase _db;

  InventoryBloc(this._db) : super(InventoryInitial()) {
    on<LoadInventory>(_onLoadInventory);
    on<InventoryUpdated>(_onInventoryUpdated);
    on<AddProduct>(_onAddProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
  }

  Future<void> _onInventoryUpdated(InventoryUpdated event, Emitter<InventoryState> emit) async {
    try {
      if (event.products.isEmpty) {
        final products = await _db.watchInventory().first;
        emit(products.isEmpty ? InventoryLoaded(const []) : InventoryLoaded(products));
      } else {
        emit(InventoryLoaded(event.products));
      }
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> _onLoadInventory(LoadInventory event, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try {
      _db.watchInventory().listen((products) {
        if (!isClosed) {
          add(InventoryUpdated(products));
        }
      });
      final products = await _db.watchInventory().first;
      emit(InventoryLoaded(products));
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> _onAddProduct(AddProduct event, Emitter<InventoryState> emit) async {
    try {
      final uuid = const Uuid();
      final product = Product(
        id: uuid.v4(),
        name: event.name,
        category: event.category,
        costPrice: event.costPrice,
        sellingPrice: event.sellingPrice,
        stockQuantity: event.stockQuantity,
        minStockAlert: event.minStockAlert,
        barCode: event.barCode,
        imagePath: event.imagePath,
      );
      await _db.addProduct(product);
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> _onUpdateProduct(UpdateProduct event, Emitter<InventoryState> emit) async {
    try {
      await _db.updateProduct(event.product);
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> _onDeleteProduct(DeleteProduct event, Emitter<InventoryState> emit) async {
    try {
      await _db.deleteProductAndCleanStorage(event.product);
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }
}

class CartCubit extends Cubit<CartState> {
  final AppDatabase _db;

  CartCubit(this._db) : super(CartInitial());

  void addToCart(Product product, {int quantity = 1}) {
    final currentState = state;
    List<CartItem> items = [];
    if (currentState is CartLoaded) {
      items = List.from(currentState.items);
    }

    final existingIndex = items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      items[existingIndex] = items[existingIndex].copyWith(
        quantity: items[existingIndex].quantity + quantity,
      );
    } else {
      items.add(CartItem(product: product, quantity: quantity));
    }

    emit(CartLoaded(items: items, discount: currentState is CartLoaded ? currentState.discount : 0.0));
  }

  void addToCartWithQuantity(Product product, int quantity) {
    addToCart(product, quantity: quantity);
  }

  void removeFromCart(String productId) {
    final currentState = state;
    if (currentState is CartLoaded) {
      final items = currentState.items.where((item) => item.product.id != productId).toList();
      emit(CartLoaded(items: items, discount: currentState.discount));
    }
  }

  void updateQuantity(String productId, int quantity) {
    final currentState = state;
    if (currentState is CartLoaded) {
      if (quantity <= 0) {
        removeFromCart(productId);
        return;
      }
      final items = currentState.items.map((item) {
        if (item.product.id == productId) {
          return item.copyWith(quantity: quantity);
        }
        return item;
      }).toList();
      emit(CartLoaded(items: items, discount: currentState.discount));
    }
  }

  void setDiscount(double discount) {
    final currentState = state;
    if (currentState is CartLoaded) {
      emit(CartLoaded(items: currentState.items, discount: discount));
    }
  }

  double get subtotal {
    final currentState = state;
    if (currentState is CartLoaded) {
      return currentState.items.fold(0.0, (sum, item) => sum + (item.product.sellingPrice * item.quantity));
    }
    return 0.0;
  }

  double get total {
    return subtotal - (state is CartLoaded ? (state as CartLoaded).discount : 0.0);
  }

  Future<void> checkout({
    required String paymentMethod,
    String? customerName,
    String? customerContact,
    DateTime? dueDate,
  }) async {
    final currentState = state;
    if (currentState is CartLoaded && currentState.items.isNotEmpty) {
      emit(CartLoading());
      try {
        final uuid = const Uuid();
        final orderId = uuid.v4();
        final items = currentState.items.map((item) => CartItemPayload(
          productId: item.product.id,
          quantity: item.quantity,
          unitPrice: item.product.sellingPrice,
          unitCost: item.product.costPrice,
        )).toList();

        await _db.checkoutCart(
          orderId: orderId,
          items: items,
          grossTotal: subtotal,
          discount: currentState.discount,
          paymentMethod: paymentMethod,
          customerName: customerName,
          customerContact: customerContact,
          debtDueDate: dueDate,
        );

        emit(CartLoaded(items: [], discount: 0.0));
        emit(CartSuccess('Checkout completed successfully!'));
      } catch (e) {
        emit(CartError(e.toString()));
        emit(CartLoaded(items: currentState.items, discount: currentState.discount));
      }
    }
  }

  void clearCart() {
    emit(CartLoaded(items: [], discount: 0.0));
  }
}

class DebtCubit extends Cubit<DebtState> {
  final AppDatabase _db;

  DebtCubit(this._db) : super(DebtInitial()) {
    _loadDebts();
  }

  void _loadDebts() {
    _db.watchActiveCreditLines().listen((debts) {
      if (!isClosed) {
        emit(DebtLoaded(debts));
      }
    });
  }

  Future<void> receivePayment(String debtId, double amount) async {
    try {
      await _db.receiveDebtPayment(debtId, amount);
    } catch (e) {
      emit(DebtError(e.toString()));
    }
  }
}

class AuditCubit extends Cubit<AuditState> {
  final AppDatabase _db;
  DateTime _selectedDate = DateTime.now();

  AuditCubit(this._db) : super(AuditInitial()) {
    loadAudit(DateTime.now());
  }

  DateTime get selectedDate => _selectedDate;

  Future<void> loadAudit(DateTime date) async {
    _selectedDate = date;
    emit(AuditLoading());
    try {
      final summary = await _db.computeAuditedMetricsForDate(date);
      emit(AuditLoaded(summary: summary, selectedDate: date));
    } catch (e) {
      emit(AuditError(e.toString()));
    }
  }

  Future<void> addExpense(String description, double amount) async {
    try {
      await _db.addExpense(description: description, amount: amount);
      await loadAudit(_selectedDate);
    } catch (e) {
      emit(AuditError(e.toString()));
    }
  }
}

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> captureAndSaveImage() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo == null) return null;

      final directory = await getApplicationDocumentsDirectory();
      final productImagesDir = Directory(p.join(directory.path, 'product_images'));
      if (!await productImagesDir.exists()) {
        await productImagesDir.create(recursive: true);
      }

      final uuid = const Uuid();
      final fileName = '${uuid.v4()}.jpg';
      final savedPath = p.join(productImagesDir.path, fileName);

      final compressedFile = await _compressImage(photo.path, savedPath);
      return compressedFile;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return null;

      final directory = await getApplicationDocumentsDirectory();
      final productImagesDir = Directory(p.join(directory.path, 'product_images'));
      if (!await productImagesDir.exists()) {
        await productImagesDir.create(recursive: true);
      }

      final uuid = const Uuid();
      final fileName = '${uuid.v4()}.jpg';
      final savedPath = p.join(productImagesDir.path, fileName);

      final compressedFile = await _compressImage(image.path, savedPath);
      return compressedFile;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> _compressImage(String sourcePath, String targetPath, {int targetSizeBytes = 200 * 1024}) async {
    try {
      final sourceFile = File(sourcePath);
      final originalBytes = await sourceFile.readAsBytes();

      final image = img.decodeImage(originalBytes);
      if (image == null) return null;

      int quality = 90;
      List<int> compressedBytes;

      do {
        compressedBytes = img.encodeJpg(image, quality: quality);
        quality -= 10;
      } while (compressedBytes.length > targetSizeBytes && quality >= 20);

      final targetFile = File(targetPath);
      await targetFile.writeAsBytes(compressedBytes);
      return targetPath;
    } catch (e) {
      return null;
    }
  }
}