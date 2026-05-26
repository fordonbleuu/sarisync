import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class InsufficientStockException implements Exception {
  final String productName;
  final int requestedQuantity;
  final int availableStock;

  InsufficientStockException({
    required this.productName,
    required this.requestedQuantity,
    required this.availableStock,
  });

  @override
  String toString() =>
      'Insufficient stock for "$productName": requested $requestedQuantity, available $availableStock';
}

class Product {
  final String id;
  final String? barCode;
  final String name;
  final String category;
  final double costPrice;
  final double sellingPrice;
  final int stockQuantity;
  final int minStockAlert;
  final String? imagePath;

  Product({
    required this.id,
    this.barCode,
    required this.name,
    required this.category,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQuantity,
    this.minStockAlert = 5,
    this.imagePath,
  });

  Product copyWith({
    String? id,
    String? barCode,
    String? name,
    String? category,
    double? costPrice,
    double? sellingPrice,
    int? stockQuantity,
    int? minStockAlert,
    String? imagePath,
  }) {
    return Product(
      id: id ?? this.id,
      barCode: barCode ?? this.barCode,
      name: name ?? this.name,
      category: category ?? this.category,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'barCode': barCode,
    'name': name,
    'category': category,
    'costPrice': costPrice,
    'sellingPrice': sellingPrice,
    'stockQuantity': stockQuantity,
    'minStockAlert': minStockAlert,
    'imagePath': imagePath,
  };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
    id: map['id'] as String,
    barCode: map['barCode'] as String?,
    name: map['name'] as String,
    category: map['category'] as String,
    costPrice: (map['costPrice'] as num).toDouble(),
    sellingPrice: (map['sellingPrice'] as num).toDouble(),
    stockQuantity: map['stockQuantity'] as int,
    minStockAlert: map['minStockAlert'] as int? ?? 5,
    imagePath: map['imagePath'] as String?,
  );
}

class SalesOrder {
  final String id;
  final DateTime transactionDate;
  final double totalAmount;
  final double discount;
  final String paymentType;
  final String status;

  SalesOrder({
    required this.id,
    required this.transactionDate,
    required this.totalAmount,
    this.discount = 0.0,
    required this.paymentType,
    required this.status,
  });
}

class SalesItem {
  final String id;
  final String orderId;
  final String productId;
  final int quantity;
  final double unitPriceAtSale;
  final double unitCostAtSale;

  SalesItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPriceAtSale,
    required this.unitCostAtSale,
  });
}

class Customer {
  final String id;
  final String name;
  final String? contact;
  final double totalDebt;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    this.contact,
    this.totalDebt = 0.0,
    required this.createdAt,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? contact,
    double? totalDebt,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      totalDebt: totalDebt ?? this.totalDebt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'contact': contact,
    'totalDebt': totalDebt,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
    id: map['id'] as String,
    name: map['name'] as String,
    contact: map['contact'] as String?,
    totalDebt: (map['totalDebt'] as num?)?.toDouble() ?? 0.0,
    createdAt: DateTime.parse(map['createdAt'] as String),
  );
}

class Debt {
  final String id;
  final String? customerId;
  final String customerName;
  final String? customerContact;
  final String? orderId;
  final double amountDue;
  final double amountPaid;
  final DateTime? dueDate;
  final String status;

  Debt({
    required this.id,
    this.customerId,
    required this.customerName,
    this.customerContact,
    this.orderId,
    required this.amountDue,
    this.amountPaid = 0.0,
    this.dueDate,
    required this.status,
  });

  double get remainingBalance => amountDue - amountPaid;

  Debt copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerContact,
    String? orderId,
    double? amountDue,
    double? amountPaid,
    DateTime? dueDate,
    String? status,
  }) {
    return Debt(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerContact: customerContact ?? this.customerContact,
      orderId: orderId ?? this.orderId,
      amountDue: amountDue ?? this.amountDue,
      amountPaid: amountPaid ?? this.amountPaid,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'customerId': customerId,
    'customerName': customerName,
    'customerContact': customerContact,
    'orderId': orderId,
    'amountDue': amountDue,
    'amountPaid': amountPaid,
    'dueDate': dueDate?.toIso8601String(),
    'status': status,
  };

  factory Debt.fromMap(Map<String, dynamic> map) => Debt(
    id: map['id'] as String,
    customerId: map['customerId'] as String?,
    customerName: map['customerName'] as String,
    customerContact: map['customerContact'] as String?,
    orderId: map['orderId'] as String?,
    amountDue: (map['amountDue'] as num?)?.toDouble() ?? 0.0,
    amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
    dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate'] as String) : null,
    status: map['status'] as String,
  );
}

class CashFlowLog {
  final String id;
  final DateTime timestamp;
  final String type;
  final double amount;
  final String description;

  CashFlowLog({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.amount,
    required this.description,
  });
}

class CartItemPayload {
  final String productId;
  final int quantity;
  final double unitPrice;
  final double unitCost;

  CartItemPayload({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.unitCost,
  });
}

class DailyFinancialSummary {
  final double grossRevenue;
  final double cogs;
  final double expenses;
  final double debtCollections;
  final double netMargin;
  final double totalOutstandingDebt;

  DailyFinancialSummary({
    required this.grossRevenue,
    required this.cogs,
    required this.expenses,
    required this.debtCollections,
    required this.netMargin,
    required this.totalOutstandingDebt,
  });
}

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  static AppDatabase get instance => _instance;
  AppDatabase._internal();

  Database? _db;
  final _productsController = StreamController<List<Product>>.broadcast();
  final _debtsController = StreamController<List<Debt>>.broadcast();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'sarisync.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products (
            id TEXT PRIMARY KEY,
            barCode TEXT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            costPrice REAL NOT NULL,
            sellingPrice REAL NOT NULL,
            stockQuantity INTEGER NOT NULL,
            minStockAlert INTEGER DEFAULT 5,
            imagePath TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE customers (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            contact TEXT,
            totalDebt REAL DEFAULT 0.0,
            createdAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE sales_orders (
            id TEXT PRIMARY KEY,
            transactionDate TEXT NOT NULL,
            totalAmount REAL NOT NULL,
            discount REAL DEFAULT 0.0,
            paymentType TEXT NOT NULL,
            status TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE sales_items (
            id TEXT PRIMARY KEY,
            orderId TEXT NOT NULL,
            productId TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            unitPriceAtSale REAL NOT NULL,
            unitCostAtSale REAL NOT NULL,
            FOREIGN KEY (orderId) REFERENCES sales_orders(id),
            FOREIGN KEY (productId) REFERENCES products(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE debts (
            id TEXT PRIMARY KEY,
            customerId TEXT,
            customerName TEXT NOT NULL,
            customerContact TEXT,
            orderId TEXT,
            amountDue REAL NOT NULL,
            amountPaid REAL DEFAULT 0.0,
            dueDate TEXT,
            status TEXT NOT NULL,
            FOREIGN KEY (customerId) REFERENCES customers(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE cash_flow_logs (
            id TEXT PRIMARY KEY,
            timestamp TEXT NOT NULL,
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            description TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS customers (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              contact TEXT,
              totalDebt REAL DEFAULT 0.0,
              createdAt TEXT NOT NULL
            )
          ''');
          try {
            await db.execute('ALTER TABLE debts ADD COLUMN customerId TEXT');
          } catch (_) {}
        }
      },
    );
  }

  Stream<List<Product>> watchInventory() {
    _loadProducts();
    return _productsController.stream;
  }

  Future<void> _loadProducts() async {
    try {
      final db = await database;
      final maps = await db.query('products');
      final products = maps.map((m) => Product.fromMap(m)).toList();
      _productsController.add(products);
    } catch (e) {
      _productsController.addError(e);
    }
  }

  Future<void> deleteProductAndCleanStorage(Product product) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [product.id]);
    await _loadProducts();
  }

  Future<void> addProduct(Product product) async {
    final db = await database;
    await db.insert('products', product.toMap());
    await _loadProducts();
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
    await _loadProducts();
  }

  Future<Customer?> findCustomerByName(String name) async {
    final db = await database;
    final maps = await db.query(
      'customers',
      where: 'LOWER(name) = LOWER(?)',
      whereArgs: [name],
    );
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  Future<Customer> findOrCreateCustomer(String name, {String? contact}) async {
    final existing = await findCustomerByName(name);
    if (existing != null) return existing;
    final uuid = const Uuid();
    final customer = Customer(
      id: uuid.v4(),
      name: name,
      contact: contact,
      createdAt: DateTime.now(),
    );
    final db = await database;
    await db.insert('customers', customer.toMap());
    return customer;
  }

  Future<void> checkoutCart({
    required String orderId,
    required List<CartItemPayload> items,
    required double grossTotal,
    required double discount,
    required String paymentMethod,
    String? customerName,
    String? customerContact,
    DateTime? debtDueDate,
  }) async {
    final db = await database;
    final uuid = const Uuid();
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.insert('sales_orders', {
        'id': orderId,
        'transactionDate': now,
        'totalAmount': grossTotal - discount,
        'discount': discount,
        'paymentType': paymentMethod,
        'status': paymentMethod == 'Utang' ? 'Unpaid' : 'Paid',
      });

      for (final item in items) {
        final products = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [item.productId],
        );
        if (products.isEmpty) continue;
        
        final product = Product.fromMap(products.first);
        if (item.quantity > product.stockQuantity) {
          throw InsufficientStockException(
            productName: product.name,
            requestedQuantity: item.quantity,
            availableStock: product.stockQuantity,
          );
        }

        await txn.insert('sales_items', {
          'id': uuid.v4(),
          'orderId': orderId,
          'productId': item.productId,
          'quantity': item.quantity,
          'unitPriceAtSale': item.unitPrice,
          'unitCostAtSale': item.unitCost,
        });

        await txn.update(
          'products',
          {'stockQuantity': product.stockQuantity - item.quantity},
          where: 'id = ?',
          whereArgs: [item.productId],
        );
      }

      if (paymentMethod == 'Utang' && customerName != null) {
        String? customerId;
        try {
          final existingMaps = await txn.query(
            'customers',
            where: 'LOWER(name) = LOWER(?)',
            whereArgs: [customerName],
          );
          if (existingMaps.isNotEmpty) {
            customerId = existingMaps.first['id'] as String;
          } else {
            final newId = uuid.v4();
            await txn.insert('customers', {
              'id': newId,
              'name': customerName,
              'contact': customerContact,
              'totalDebt': 0.0,
              'createdAt': DateTime.now().toIso8601String(),
            });
            customerId = newId;
          }
        } catch (_) {}

        await txn.insert('debts', {
          'id': uuid.v4(),
          'customerId': customerId,
          'customerName': customerName,
          'customerContact': customerContact,
          'orderId': orderId,
          'amountDue': grossTotal - discount,
          'amountPaid': 0.0,
          'dueDate': debtDueDate?.toIso8601String(),
          'status': 'Active',
        });
      }

      if (paymentMethod != 'Utang') {
        await txn.insert('cash_flow_logs', {
          'id': uuid.v4(),
          'timestamp': now,
          'type': 'IN',
          'amount': grossTotal - discount,
          'description': 'Sale - $orderId',
        });
      }
    });

    await _loadProducts();
    await loadAllDebts();
  }

  Future<void> loadAllDebts() async {
    try {
      final db = await database;
      final maps = await db.query('debts');
      final debts = maps.map((m) => Debt.fromMap(m)).toList();
      _debtsController.add(debts);
    } catch (e) {
      _debtsController.addError(e);
    }
  }

  Stream<List<Debt>> watchAllDebts() {
    loadAllDebts();
    return _debtsController.stream;
  }

  Future<List<CashFlowLog>> getDebtPayments(String debtId) async {
    final db = await database;
    final maps = await db.query(
      'cash_flow_logs',
      where: 'description LIKE ?',
      whereArgs: ['%Debt Payment - $debtId'],
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => CashFlowLog(
      id: m['id'] as String,
      timestamp: DateTime.parse(m['timestamp'] as String),
      type: m['type'] as String,
      amount: (m['amount'] as num).toDouble(),
      description: m['description'] as String,
    )).toList();
  }

  Future<void> receiveDebtPayment(String debtId, double collectedAmount) async {
    final db = await database;
    final uuid = const Uuid();

    await db.transaction((txn) async {
      final debts = await txn.query(
        'debts',
        where: 'id = ?',
        whereArgs: [debtId],
      );

      if (debts.isEmpty) return;

      final debt = Debt.fromMap(debts.first);
      final newAmountPaid = debt.amountPaid + collectedAmount;
      final isSettled = newAmountPaid >= debt.amountDue;

      await txn.update(
        'debts',
        {
          'amountPaid': isSettled ? debt.amountDue : newAmountPaid,
          'status': isSettled ? 'Settled' : 'Active',
        },
        where: 'id = ?',
        whereArgs: [debtId],
      );

      await txn.insert('cash_flow_logs', {
        'id': uuid.v4(),
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'IN',
        'amount': collectedAmount,
        'description': isSettled ? 'Full Debt Payment - $debtId' : 'Partial Debt Payment - $debtId',
      });
    });

    await loadAllDebts();
  }

  Future<void> addManualDebt({
    required String customerName,
    String? customerContact,
    required double amount,
    DateTime? dueDate,
  }) async {
    final db = await database;
    final uuid = const Uuid();

    final customer = await findOrCreateCustomer(customerName, contact: customerContact);

    await db.insert('debts', {
      'id': uuid.v4(),
      'customerId': customer.id,
      'customerName': customerName,
      'customerContact': customerContact,
      'amountDue': amount,
      'amountPaid': 0.0,
      'dueDate': dueDate?.toIso8601String(),
      'status': 'Active',
    });

    await loadAllDebts();
  }

  Future<DailyFinancialSummary> computeAuditedMetricsForDate(DateTime lookupDate) async {
    final db = await database;
    final startOfDay = DateTime(lookupDate.year, lookupDate.month, lookupDate.day).toIso8601String();
    final endOfDay = DateTime(lookupDate.year, lookupDate.month, lookupDate.day + 1).toIso8601String();

    final orders = await db.query(
      'sales_orders',
      where: 'transactionDate >= ? AND transactionDate < ?',
      whereArgs: [startOfDay, endOfDay],
    );

    final orderIds = orders.map((o) => o['id'] as String).toList();
    
    double grossRevenue = orders.fold(0.0, (sum, o) => sum + ((o['totalAmount'] as num).toDouble()));
    
    double totalCogs = 0;
    if (orderIds.isNotEmpty) {
      final placeholders = List.filled(orderIds.length, '?').join(',');
      final items = await db.rawQuery(
        'SELECT * FROM sales_items WHERE orderId IN ($placeholders)',
        orderIds,
      );
      totalCogs = items.fold(0.0, (sum, i) => sum + ((i['unitCostAtSale'] as num).toDouble() * (i['quantity'] as int)));
    }

    final expenses = await db.query(
      'cash_flow_logs',
      where: 'type = ? AND timestamp >= ? AND timestamp < ?',
      whereArgs: ['OUT', startOfDay, endOfDay],
    );
    double totalExpenses = expenses.fold(0.0, (sum, e) => sum + ((e['amount'] as num).toDouble()));

    final collections = await db.query(
      'cash_flow_logs',
      where: 'type = ? AND description LIKE ? AND timestamp >= ? AND timestamp < ?',
      whereArgs: ['IN', '%Debt Payment - %', startOfDay, endOfDay],
    );
    double totalDebtCollections = collections.fold(0.0, (sum, c) => sum + ((c['amount'] as num).toDouble()));

    final activeDebts = await db.query('debts', where: 'status = ?', whereArgs: ['Active']);
    double totalOutstandingDebt = activeDebts.fold(0.0, (sum, d) => sum + ((d['amountDue'] as num).toDouble() - (d['amountPaid'] as num).toDouble()));

    return DailyFinancialSummary(
      grossRevenue: grossRevenue,
      cogs: totalCogs,
      expenses: totalExpenses,
      debtCollections: totalDebtCollections,
      netMargin: grossRevenue - totalCogs - totalExpenses,
      totalOutstandingDebt: totalOutstandingDebt,
    );
  }

  Future<List<SalesItem>> getSalesItemsForDate(DateTime lookupDate) async {
    final db = await database;
    final startOfDay = DateTime(lookupDate.year, lookupDate.month, lookupDate.day).toIso8601String();
    final endOfDay = DateTime(lookupDate.year, lookupDate.month, lookupDate.day + 1).toIso8601String();

    final orders = await db.query(
      'sales_orders',
      where: 'transactionDate >= ? AND transactionDate < ?',
      whereArgs: [startOfDay, endOfDay],
    );

    final orderIds = orders.map((o) => o['id'] as String).toList();
    if (orderIds.isEmpty) return [];

    final placeholders = List.filled(orderIds.length, '?').join(',');
    final items = await db.rawQuery(
      'SELECT * FROM sales_items WHERE orderId IN ($placeholders)',
      orderIds,
    );

    return items.map((i) => SalesItem(
      id: i['id'] as String,
      orderId: i['orderId'] as String,
      productId: i['productId'] as String,
      quantity: i['quantity'] as int,
      unitPriceAtSale: (i['unitPriceAtSale'] as num).toDouble(),
      unitCostAtSale: (i['unitCostAtSale'] as num).toDouble(),
    )).toList();
  }

  Future<List<Product>> getProductsForItems(List<SalesItem> items) async {
    final db = await database;
    final productIds = items.map((i) => i.productId).toList();
    if (productIds.isEmpty) return [];

    final placeholders = List.filled(productIds.length, '?').join(',');
    final maps = await db.rawQuery(
      'SELECT * FROM products WHERE id IN ($placeholders)',
      productIds,
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<void> addExpense({required String description, required double amount}) async {
    final db = await database;
    final uuid = const Uuid();
    await db.insert('cash_flow_logs', {
      'id': uuid.v4(),
      'timestamp': DateTime.now().toIso8601String(),
      'type': 'OUT',
      'amount': amount,
      'description': description,
    });
  }

  void dispose() {
    _productsController.close();
    _debtsController.close();
  }
}