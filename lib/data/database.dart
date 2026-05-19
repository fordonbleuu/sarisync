import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get barcode => text().nullable()();
  RealColumn get price => real()();
  RealColumn get costPrice => real()();
  IntColumn get stock => integer().withDefault(const Constant(0))();
  TextColumn get imagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get totalAmount => real()();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  TextColumn get paymentType => text()();
  TextColumn get status => text().withDefault(const Constant('Paid'))();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(Sales, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
  RealColumn get unitCost => real()();
}

class Debts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get customerName => text().withLength(min: 1)();
  TextColumn get customerContact => text().nullable()();
  IntColumn get saleId => integer().references(Sales, #id)();
  RealColumn get amount => real()();
  RealColumn get amountPaid => real().withDefault(const Constant(0.0))();
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class CashFlowLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  RealColumn get amount => real()();
  TextColumn get description => text()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Products, Sales, SaleItems, Debts, CashFlowLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'sarisync.db'));
      return NativeDatabase.createInBackground(file);
    });
  }

  Stream<List<Product>> watchAllProducts() => select(products).watch();

  Future<List<Product>> getAllProducts() => select(products).get();

  Future<int> insertProduct(ProductsCompanion product) =>
      into(products).insert(product);

  Future<bool> updateProduct(ProductsCompanion product) =>
      update(products).replace(product);

  Future<int> deleteProduct(int id) =>
      (delete(products)..where((t) => t.id.equals(id))).go();

  Future<void> decrementStock(int productId, int quantity) async {
    final product = await (select(products)..where((t) => t.id.equals(productId))).getSingleOrNull();
    if (product != null) {
      await (update(products)..where((t) => t.id.equals(productId)))
          .write(ProductsCompanion(stock: Value(product.stock - quantity)));
    }
  }

  Stream<List<Sale>> watchAllSales() =>
      (select(sales)..orderBy([(t) => OrderingTerm.desc(t.timestamp)])).watch();

  Stream<List<Sale>> watchSalesForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(sales)
          ..where((t) => t.timestamp.isBiggerOrEqualValue(startOfDay) &
              t.timestamp.isSmallerThanValue(endOfDay))
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .watch();
  }

  Future<int> insertSale(SalesCompanion sale) => into(sales).insert(sale);

  Future<int> insertSaleItem(SaleItemsCompanion item) => into(saleItems).insert(item);

  Future<void> insertSaleWithItems({
    required double totalAmount,
    required double discount,
    required String paymentType,
    required String status,
    required List<SaleItemData> items,
  }) async {
    await transaction(() async {
      final saleId = await into(sales).insert(SalesCompanion.insert(
        totalAmount: totalAmount,
        discount: Value(discount),
        paymentType: paymentType,
        status: Value(status),
      ));

      for (final item in items) {
        await into(saleItems).insert(SaleItemsCompanion.insert(
          saleId: saleId,
          productId: item.productId,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          unitCost: item.unitCost,
        ));

        await decrementStock(item.productId, item.quantity);
      }

      if (paymentType == 'Cash' || paymentType == 'Cash') {
        await into(cashFlowLogs).insert(CashFlowLogsCompanion.insert(
          type: 'IN',
          amount: totalAmount - discount,
          description: 'Sale #$saleId',
        ));
      }
    });
  }

  Stream<List<Debt>> watchActiveDebts() =>
      (select(debts)..where((t) => t.isPaid.equals(false))).watch();

  Stream<List<Debt>> watchAllDebts() =>
      (select(debts)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  Future<int> insertDebt(DebtsCompanion debt) => into(debts).insert(debt);

  Future<void> updateDebtPayment(String debtId, double amount) async {
    final debt = await (select(debts)..where((t) => t.id.equals(int.parse(debtId)))).getSingleOrNull();
    if (debt != null) {
      final newAmountPaid = debt.amountPaid + amount;
      final isFullyPaid = newAmountPaid >= debt.amount;

      await (update(debts)..where((t) => t.id.equals(debt.id))).write(
        DebtsCompanion(
          amountPaid: Value(newAmountPaid),
          isPaid: Value(isFullyPaid),
        ),
      );

      await into(cashFlowLogs).insert(CashFlowLogsCompanion.insert(
        type: 'IN',
        amount: amount,
        description: isFullyPaid ? 'Full Debt Payment - $debtId' : 'Partial Debt Payment - $debtId',
      ));
    }
  }

  Stream<List<CashFlowLog>> watchAllCashFlowLogs() =>
      (select(cashFlowLogs)..orderBy([(t) => OrderingTerm.desc(t.timestamp)])).watch();

  Stream<List<CashFlowLog>> watchCashFlowForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(cashFlowLogs)
          ..where((t) => t.timestamp.isBiggerOrEqualValue(startOfDay) &
              t.timestamp.isSmallerThanValue(endOfDay))
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .watch();
  }

  Future<int> insertCashFlow(CashFlowLogsCompanion log) =>
      into(cashFlowLogs).insert(log);

  Future<double> getTotalRevenueForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final result = await (selectOnly(sales)
          ..addColumns([sales.totalAmount.sum()])
          ..where(sales.timestamp.isBiggerOrEqualValue(startOfDay) &
              sales.timestamp.isSmallerThanValue(endOfDay)))
        .getSingle();
    return result.read(sales.totalAmount.sum()) ?? 0.0;
  }

  Future<double> getTotalExpensesForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final result = await (selectOnly(cashFlowLogs)
          ..addColumns([cashFlowLogs.amount.sum()])
          ..where(cashFlowLogs.type.equals('OUT') &
              cashFlowLogs.timestamp.isBiggerOrEqualValue(startOfDay) &
              cashFlowLogs.timestamp.isSmallerThanValue(endOfDay)))
        .getSingle();
    return result.read(cashFlowLogs.amount.sum()) ?? 0.0;
  }

  Future<List<SaleItemWithProduct>> getSaleItemsWithProducts(int saleId) async {
    final query = select(saleItems).join([
      innerJoin(products, products.id.equalsExp(saleItems.productId)),
    ])..where(saleItems.saleId.equals(saleId));

    final results = await query.get();
    return results.map((row) {
      return SaleItemWithProduct(
        saleItem: row.readTable(saleItems),
        product: row.readTable(products),
      );
    }).toList();
  }
}

class SaleItemData {
  final int productId;
  final int quantity;
  final double unitPrice;
  final double unitCost;

  SaleItemData({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.unitCost,
  });
}

class SaleItemWithProduct {
  final SaleItem saleItem;
  final Product product;

  SaleItemWithProduct({required this.saleItem, required this.product});
}