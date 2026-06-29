import 'package:flutter/material.dart';

class StockActionWidget extends StatelessWidget {
  final String code;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onReduce;

  const StockActionWidget({
    super.key,
    required this.code,
    required this.qty,
    required this.onAdd,
    required this.onReduce,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: qty > 0 ? onReduce : null,
        ),
        Text(
          qty.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: onAdd,
        ),
      ],
    );
  }
}
