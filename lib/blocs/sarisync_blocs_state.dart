part of 'sarisync_blocs.dart';

abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final List<Product> products;

  const InventoryLoaded(this.products);

  @override
  List<Object?> get props => [products];
}

class InventoryError extends InventoryState {
  final String message;

  const InventoryError(this.message);

  @override
  List<Object?> get props => [message];
}

class CartItem extends Equatable {
  final Product product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  double get total => product.sellingPrice * quantity;

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [product, quantity];
}

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoaded extends CartState {
  final List<CartItem> items;
  final double discount;

  const CartLoaded({required this.items, this.discount = 0.0});

  @override
  List<Object?> get props => [items, discount];
}

class CartLoading extends CartState {}

class CartSuccess extends CartState {
  final String message;

  const CartSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class CartCheckoutSuccess extends CartState {
  final List<CartItem> items;
  final double discount;
  final String message;

  const CartCheckoutSuccess({
    required this.items,
    required this.discount,
    required this.message,
  });

  @override
  List<Object?> get props => [items, discount, message];
}

class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}

abstract class DebtState extends Equatable {
  const DebtState();

  @override
  List<Object?> get props => [];
}

class DebtInitial extends DebtState {}

class DebtLoaded extends DebtState {
  final List<Debt> debts;
  final String searchQuery;
  final bool showOnlyActive;

  const DebtLoaded({
    required this.debts,
    this.searchQuery = '',
    this.showOnlyActive = true,
  });

  List<Debt> get filteredDebts {
    var filtered = showOnlyActive
        ? debts.where((d) => d.status == 'Active').toList()
        : debts;

    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((d) => d.customerName.toLowerCase().contains(searchQuery.toLowerCase()) ||
              (d.customerContact?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false))
          .toList();
    }
    return filtered;
  }

  @override
  List<Object?> get props => [debts, searchQuery, showOnlyActive];

  DebtLoaded copyWith({
    List<Debt>? debts,
    String? searchQuery,
    bool? showOnlyActive,
  }) {
    return DebtLoaded(
      debts: debts ?? this.debts,
      searchQuery: searchQuery ?? this.searchQuery,
      showOnlyActive: showOnlyActive ?? this.showOnlyActive,
    );
  }
}

class DebtError extends DebtState {
  final String message;

  const DebtError(this.message);

  @override
  List<Object?> get props => [message];
}

abstract class AuditState extends Equatable {
  const AuditState();

  @override
  List<Object?> get props => [];
}

class AuditInitial extends AuditState {}

class AuditLoading extends AuditState {}

class AuditLoaded extends AuditState {
  final DailyFinancialSummary summary;
  final DateTime selectedDate;

  const AuditLoaded({required this.summary, required this.selectedDate});

  @override
  List<Object?> get props => [summary, selectedDate];
}

class AuditError extends AuditState {
  final String message;

  const AuditError(this.message);

  @override
  List<Object?> get props => [message];
}

abstract class ExpenseState extends Equatable {
  const ExpenseState();

  @override
  List<Object?> get props => [];
}

class ExpenseInitial extends ExpenseState {}

class ExpenseLoading extends ExpenseState {}

class ExpenseLoaded extends ExpenseState {
  final List<CashFlowLog> expenses;

  const ExpenseLoaded(this.expenses);

  @override
  List<Object?> get props => [expenses];
}

class ExpenseError extends ExpenseState {
  final String message;

  const ExpenseError(this.message);

  @override
  List<Object?> get props => [message];
}