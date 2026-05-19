import 'dart:async';
import 'dart:io';

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

class Debt {
  final String id;
  final String customerName;
  final String? customerContact;
  final String? orderId;
  final double amountDue;
  final double amountPaid;
  final DateTime? dueDate;
  final String status;

  Debt({
    required this.id,
    required this.customerName,
    this.customerContact,
    this.orderId,
    required this.amountDue,
    this.amountPaid = 0.0,
    this.dueDate,
    required this.status,
  });

  Debt copyWith({
    String? id,
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
      customerName: customerName ?? this.customerName,
      customerContact: customerContact ?? this.customerContact,
      orderId: orderId ?? this.orderId,
      amountDue: amountDue ?? this.amountDue,
      amountPaid: amountPaid ?? this.amountPaid,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
    );
  }
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
  final double netMargin;

  DailyFinancialSummary({
    required this.grossRevenue,
    required this.cogs,
    required this.expenses,
    required this.netMargin,
  });
}

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  static AppDatabase get instance => _instance;
  AppDatabase._internal();

  final List<Product> _products = [];
  final List<SalesOrder> _salesOrders = [];
  final List<SalesItem> _salesItems = [];
  final List<Debt> _debts = [];
  final List<CashFlowLog> _cashFlowLogs = [];

  final _productsController = StreamController<List<Product>>.broadcast();
  final _debtsController = StreamController<List<Debt>>.broadcast();

  Stream<List<Product>> watchInventory() {
    _productsController.add(_products);
    return _productsController.stream;
  }

  Future<void> deleteProductAndCleanStorage(Product product) async {
    _products.removeWhere((p) => p.id == product.id);
    if (product.imagePath != null) {
      final file = File(product.imagePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    _productsController.add(_products);
  }

  Future<void> addProduct(Product product) async {
    _products.add(product);
    _productsController.add(_products);
  }

  Future<void> updateProduct(Product product) async {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _products[index] = product;
      _productsController.add(_products);
    }
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
    for (final item in items) {
      final productIndex = _products.indexWhere((p) => p.id == item.productId);
      if (productIndex >= 0) {
        final product = _products[productIndex];
        if (item.quantity > product.stockQuantity) {
          throw InsufficientStockException(
            productName: product.name,
            requestedQuantity: item.quantity,
            availableStock: product.stockQuantity,
          );
        }
      }
    }

    final uuid = const Uuid();
    final now = DateTime.now();

    final order = SalesOrder(
      id: orderId,
      transactionDate: now,
      totalAmount: grossTotal - discount,
      discount: discount,
      paymentType: paymentMethod,
      status: paymentMethod == 'Utang' ? 'Unpaid' : 'Paid',
    );
    _salesOrders.add(order);

    for (final item in items) {
      final salesItem = SalesItem(
        id: uuid.v4(),
        orderId: orderId,
        productId: item.productId,
        quantity: item.quantity,
        unitPriceAtSale: item.unitPrice,
        unitCostAtSale: item.unitCost,
      );
      _salesItems.add(salesItem);

      final productIndex = _products.indexWhere((p) => p.id == item.productId);
      if (productIndex >= 0) {
        final product = _products[productIndex];
        _products[productIndex] = product.copyWith(
          stockQuantity: product.stockQuantity - item.quantity,
        );
      }
    }
    _productsController.add(_products);

    if (paymentMethod == 'Utang' && customerName != null) {
      final debt = Debt(
        id: uuid.v4(),
        customerName: customerName,
        customerContact: customerContact,
        orderId: orderId,
        amountDue: grossTotal - discount,
        dueDate: debtDueDate,
        status: 'Active',
      );
      _debts.add(debt);
      _debtsController.add(_debts);
    }

    if (paymentMethod != 'Utang') {
      final cashFlow = CashFlowLog(
        id: uuid.v4(),
        timestamp: now,
        type: 'IN',
        amount: grossTotal - discount,
        description: 'Sale - $orderId',
      );
      _cashFlowLogs.add(cashFlow);
    }
  }

  Stream<List<Debt>> watchActiveCreditLines() {
    final activeDebts = _debts.where((d) => d.status == 'Active').toList();
    _debtsController.add(activeDebts);
    return _debtsController.stream;
  }

  Future<void> receiveDebtPayment(String debtId, double collectedAmount) async {
    final index = _debts.indexWhere((d) => d.id == debtId);
    if (index >= 0) {
      final debt = _debts[index];
      final newAmountPaid = debt.amountPaid + collectedAmount;
      final uuid = const Uuid();

      if (newAmountPaid >= debt.amountDue) {
        _debts[index] = debt.copyWith(
          amountPaid: debt.amountDue,
          status: 'Settled',
        );
        _cashFlowLogs.add(CashFlowLog(
          id: uuid.v4(),
          timestamp: DateTime.now(),
          type: 'IN',
          amount: collectedAmount,
          description: 'Debt Payment - $debtId',
        ));
      } else {
        _debts[index] = debt.copyWith(amountPaid: newAmountPaid);
        _cashFlowLogs.add(CashFlowLog(
          id: uuid.v4(),
          timestamp: DateTime.now(),
          type: 'IN',
          amount: collectedAmount,
          description: 'Partial Debt Payment - $debtId',
        ));
      }
      _debtsController.add(_debts.where((d) => d.status == 'Active').toList());
    }
  }

  Future<DailyFinancialSummary> computeAuditedMetricsForDate(DateTime lookupDate) async {
    final startOfDay = DateTime(lookupDate.year, lookupDate.month, lookupDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final ordersOfDay = _salesOrders.where((o) =>
        o.transactionDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
        o.transactionDate.isBefore(endOfDay)).toList();

    final orderIds = ordersOfDay.map((o) => o.id).toSet();
    final itemsOfDay = _salesItems.where((i) => orderIds.contains(i.orderId)).toList();

    final expensesOfDay = _cashFlowLogs.where((l) =>
        l.type == 'OUT' &&
        l.timestamp.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
        l.timestamp.isBefore(endOfDay)).toList();

    double grossRevenue = 0;
    double totalCogs = 0;

    for (final order in ordersOfDay) {
      grossRevenue += order.totalAmount;
    }

    for (final item in itemsOfDay) {
      totalCogs += item.unitCostAtSale * item.quantity;
    }

    double totalExpenses = 0;
    for (final expense in expensesOfDay) {
      totalExpenses += expense.amount;
    }

    return DailyFinancialSummary(
      grossRevenue: grossRevenue,
      cogs: totalCogs,
      expenses: totalExpenses,
      netMargin: grossRevenue - totalCogs - totalExpenses,
    );
  }

  Future<List<SalesItem>> getSalesItemsForDate(DateTime lookupDate) async {
    final startOfDay = DateTime(lookupDate.year, lookupDate.month, lookupDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final ordersOfDay = _salesOrders.where((o) =>
        o.transactionDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
        o.transactionDate.isBefore(endOfDay)).toList();

    final orderIds = ordersOfDay.map((o) => o.id).toSet();
    return _salesItems.where((i) => orderIds.contains(i.orderId)).toList();
  }

  Future<List<Product>> getProductsForItems(List<SalesItem> items) async {
    final productMap = <String, Product>{};
    for (final item in items) {
      final productIndex = _products.indexWhere((p) => p.id == item.productId);
      if (productIndex >= 0 && !productMap.containsKey(item.productId)) {
        productMap[item.productId] = _products[productIndex];
      }
    }
    return productMap.values.toList();
  }

  Future<void> addExpense({
    required String description,
    required double amount,
  }) async {
    final uuid = const Uuid();
    _cashFlowLogs.add(CashFlowLog(
      id: uuid.v4(),
      timestamp: DateTime.now(),
      type: 'OUT',
      amount: amount,
      description: description,
    ));
  }

  void dispose() {
    _productsController.close();
    _debtsController.close();
  }
}