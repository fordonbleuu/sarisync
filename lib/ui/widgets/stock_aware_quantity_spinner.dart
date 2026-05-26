import 'package:flutter/material.dart';

class StockAwareQuantitySpinner extends StatelessWidget {
  final int quantity;
  final int maxStock;
  final ValueChanged<int> onChanged;
  final bool enabled;

  const StockAwareQuantitySpinner({
    super.key,
    required this.quantity,
    required this.maxStock,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final canDecrement = enabled && quantity > 0;
    final canIncrement = enabled && quantity < maxStock;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          color: canDecrement ? Colors.red : Colors.grey.shade300,
          onPressed: canDecrement ? () => onChanged(quantity - 1) : null,
        ),
        SizedBox(
          width: 40,
          child: Center(
            child: Text(
              '$quantity',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: quantity > 0
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          color: canIncrement
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade300,
          onPressed: canIncrement
              ? () => onChanged(quantity + 1)
              : () => _showStockWarning(context),
        ),
      ],
    );
  }

  void _showStockWarning(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cannot exceed available stock ($maxStock items)'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class StockAwareQuantityInput extends StatelessWidget {
  final int quantity;
  final int maxStock;
  final ValueChanged<int> onChanged;
  final bool enabled;

  const StockAwareQuantityInput({
    super.key,
    required this.quantity,
    required this.maxStock,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove, size: 18),
          onPressed: enabled && quantity > 0
              ? () => onChanged((quantity - 1).clamp(0, maxStock))
              : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 32),
          alignment: Alignment.center,
          child: Text(
            '$quantity',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add, size: 18),
          onPressed: enabled && quantity < maxStock
              ? () => onChanged((quantity + 1).clamp(0, maxStock))
              : () => _showStockWarning(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  void _showStockWarning(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Maximum stock reached ($maxStock)'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}