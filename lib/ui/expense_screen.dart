import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/sarisync_blocs.dart';
import '../design_system/sari_design_system.dart';

class ExpenseScreen extends StatelessWidget {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Expenses'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: SariGradients.appBar,
          ),
        ),
      ),
      body: BlocBuilder<ExpenseCubit, ExpenseState>(
        builder: (context, state) {
          if (state is ExpenseLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ExpenseError) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is ExpenseLoaded) {
            final expenses = state.expenses;
            if (expenses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'No expenses recorded yet',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return SariTransactionTile(
                  title: expense.description,
                  subtitle: 'Expense',
                  dateTime: expense.timestamp,
                  amount: expense.amount,
                  isPositive: false,
                  icon: Icons.receipt_long,
                  iconColor: SariColors.error,
                );
              },
            );
          }
          return const Center(child: Text('Initial State'));
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseDialog(context),
        label: const Text('Add Expense'),
        icon: const Icon(Icons.add),
        backgroundColor: SariColors.error,
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
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
                  const Icon(Icons.receipt_long, color: SariColors.error),
                  const SizedBox(width: 8),
                  Text(
                    'Record Expense',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g., Electricity bill, Rent, Snacks',
                  prefixIcon: Icon(Icons.description),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.money),
                  prefixText: '₱',
                ),
              ),
              const SizedBox(height: 24),
              SariActionButton(
                label: 'Save Expense',
                backgroundColor: SariColors.error,
                onPressed: () async {
                  final description = descriptionController.text.trim();
                  final amount = double.tryParse(amountController.text);

                  if (description.isEmpty || amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a description and valid amount'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  await context.read<ExpenseCubit>().addExpense(description, amount);
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}