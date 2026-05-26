import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../design_system/sari_design_system.dart';
import 'package:intl/intl.dart';
import '../data/sarisync_database.dart';
import '../blocs/sarisync_blocs.dart';

class DebtLedgerScreen extends StatelessWidget {
  const DebtLedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DebtCubit, DebtState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Debt Ledger'),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: SariGradients.appBar,
              ),
            ),
          ),
          body: state is DebtInitial
              ? const Center(child: CircularProgressIndicator())
              : state is DebtError
                  ? Center(child: Text('Error: ${state.message}'))
                  : state is DebtLoaded
                      ? _DebtLedgerContent(state: state)
                      : const Center(child: Text('Unknown state')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddDebtDialog(context),
            backgroundColor: SariColors.primaryGreen,
            icon: const Icon(Icons.add_card, color: Colors.white),
            label: const Text('Add Debt', style: TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }

  void _showAddDebtDialog(BuildContext context) {
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final amountController = TextEditingController();
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
                      const Icon(Icons.add_card, color: SariColors.primaryGreen),
                      const SizedBox(width: 8),
                      Text(
                        'New Debt Record',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name *',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contactController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Number',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount Due *',
                      prefixIcon: Icon(Icons.money),
                      border: OutlineInputBorder(),
                      prefixText: '₱',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                            ? DateFormat('MMM d, yyyy').format(selectedDueDate!)
                            : 'Select due date',
                        style: TextStyle(
                          color: selectedDueDate != null ? null : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      gradient: SariGradients.buttonSuccess,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final amount = double.tryParse(amountController.text);

                        if (name.isEmpty || amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill required fields'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        await context.read<DebtCubit>().createManualDebt(
                              customerName: name,
                              customerContact: contactController.text.trim().isNotEmpty
                                  ? contactController.text.trim()
                                  : null,
                              amount: amount,
                              dueDate: selectedDueDate,
                            );

                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Debt record created'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Create Record'),
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
}

class _DebtLedgerContent extends StatefulWidget {
  final DebtLoaded state;
  const _DebtLedgerContent({required this.state});

  @override
  State<_DebtLedgerContent> createState() => _DebtLedgerContentState();
}

class _DebtLedgerContentState extends State<_DebtLedgerContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.state.searchQuery;
  }

  double get _totalOutstanding {
    return widget.state.debts
        .where((d) => d.status == 'Active')
        .fold(0.0, (sum, debt) => sum + debt.remainingBalance);
  }

  @override
  Widget build(BuildContext context) {
    final filteredDebts = widget.state.filteredDebts;

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                SariColors.primaryGreen,
                SariColors.primaryGreenDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: SariColors.primaryGreen.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Total Outstanding',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '₱${_totalOutstanding.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.state.debts.where((d) => d.status == 'Active').length} active credit accounts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search customer...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    context.read<DebtCubit>().setSearchQuery(value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Active Only'),
                selected: widget.state.showOnlyActive,
                onSelected: (selected) {
                  context.read<DebtCubit>().toggleShowOnlyActive(selected);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredDebts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No matching debts found',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDebts.length,
                  itemBuilder: (context, index) {
                    final debt = filteredDebts[index];
                    return _DebtCard(debt: debt);
                  },
                ),
        ),
      ],
    );
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  const _DebtCard({required this.debt});

  @override
  Widget build(BuildContext context) {
    final remaining = debt.remainingBalance;
    final progress = debt.amountDue > 0 ? debt.amountPaid / debt.amountDue : 0.0;
    final isOverdue = debt.status == 'Active' && debt.dueDate != null && debt.dueDate!.isBefore(DateTime.now());
    final isSettled = debt.status == 'Settled';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: isSettled ? SariGradients.surfaceSubtle : SariGradients.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: isOverdue
            ? Border.all(color: Colors.red.shade400, width: 2)
            : Border.all(color: SariColors.divider),
        boxShadow: [
          if (isOverdue)
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.1),
              blurRadius: 8,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isSettled ? Colors.grey.shade200 : Colors.orange.shade100,
                  child: Text(
                    debt.customerName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: isSettled ? Colors.grey.shade600 : Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.customerName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isSettled ? Colors.grey.shade600 : null,
                          decoration: isSettled ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (debt.customerContact != null)
                        Text(
                          debt.customerContact!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'OVERDUE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isSettled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'SETTLED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount Due',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '₱${debt.amountDue.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isSettled ? Colors.grey.shade600 : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Remaining',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          '₱${remaining.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isSettled
                                ? Colors.green
                                : (remaining > 0 ? Colors.red : Colors.green),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRBar(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isSettled ? Colors.green : (progress >= 1.0 ? Colors.green : Colors.orange),
              ),
              height: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Paid: ₱${debt.amountPaid.toStringAsFixed(2)} (${(progress * 100).toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (debt.dueDate != null)
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: isOverdue ? Colors.red : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${DateFormat('MMM d').format(debt.dueDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverdue ? Colors.red : Colors.grey.shade600,
                          fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (!isSettled)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        gradient: SariGradients.buttonSuccess,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _showPaymentSheet(context, debt),
                        icon: const Icon(Icons.payments),
                        label: const Text('Collect'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showHistorySheet(context, debt),
                    icon: const Icon(Icons.history),
                    label: const Text('History'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: SariColors.primaryGreen),
                      foregroundColor: SariColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentSheet(BuildContext context, Debt debt) {
    final amountController = TextEditingController();
    final remaining = debt.remainingBalance;

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
                  Icon(Icons.payments, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Collect Payment',
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Customer: ${debt.customerName}',
                style: TextStyle(color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: SariGradients.cardSubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remaining Balance',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '₱${remaining.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Payment Amount',
                  prefixIcon: Icon(Icons.money),
                  border: OutlineInputBorder(),
                  hintText: 'Enter amount collected',
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _QuickAmountChip(label: 'Full', amount: remaining, controller: amountController),
                  _QuickAmountChip(label: 'Half', amount: remaining / 2, controller: amountController),
                  _QuickAmountChip(label: '100', amount: 100, controller: amountController),
                  _QuickAmountChip(label: '200', amount: 200, controller: amountController),
                  _QuickAmountChip(label: '500', amount: 500, controller: amountController),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: SariGradients.buttonSuccess,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid amount'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (amount > remaining) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Amount exceeds remaining balance'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    await context.read<DebtCubit>().receivePayment(debt.id, amount);
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Payment of ₱${amount.toStringAsFixed(2)} recorded'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm Payment'),
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
  }

  void _showHistorySheet(BuildContext context, Debt debt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.history, color: SariColors.primaryGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payment History',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Customer: ${debt.customerName}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const Divider(height: 32),
              Expanded(
                child: FutureBuilder<List<CashFlowLog>>(
                  future: context.read<DebtCubit>().getPaymentHistory(debt.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    final history = snapshot.data ?? [];
                    if (history.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notes, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'No payments recorded yet',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: history.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final log = history[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            child: Icon(Icons.payment, size: 20),
                          ),
                          title: Text(
                            '₱${log.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            DateFormat('MMM d, yyyy • hh:mm a').format(log.timestamp),
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: log.description.contains('Full')
                                  ? Colors.green.shade50
                                  : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              log.description.contains('Full') ? 'Full' : 'Partial',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: log.description.contains('Full')
                                    ? Colors.green.shade700
                                    : Colors.blue.shade700,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickAmountChip extends StatelessWidget {
  final String label;
  final double amount;
  final TextEditingController controller;

  const _QuickAmountChip({
    required this.label,
    required this.amount,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        controller.text = amount.toStringAsFixed(2);
      },
    );
  }
}

class ClipRBar extends StatelessWidget {
  final double value;
  final Color backgroundColor;
  final Animation<Color?> valueColor;
  final double height;
  final BorderRadius borderRadius;

  const ClipRBar({
    super.key,
    required this.value,
    required this.backgroundColor,
    required this.valueColor,
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: valueColor.value,
            borderRadius: borderRadius,
          ),
        ),
      ),
    );
  }
}