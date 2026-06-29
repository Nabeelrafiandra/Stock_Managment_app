import 'package:flutter/material.dart';
import 'stock_action_widget.dart';

class StockListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> stock;
  final Function(String code) onAdd;
  final Function(String code) onReduce;

  const StockListWidget({
    super.key,
    required this.stock,
    required this.onAdd,
    required this.onReduce,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: stock.length,
      itemBuilder: (_, i) {
        final item = stock[i];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text(item['name']),
            subtitle: Text('Kode: ${item['code']}'),
            trailing: StockActionWidget(
              code: item['code'],
              qty: item['qty'],
              onAdd: () => onAdd(item['code']),
              onReduce: () => onReduce(item['code']),
            ),
          ),
        );
      },
    );
  }
}
