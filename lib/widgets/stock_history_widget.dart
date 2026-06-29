import 'package:flutter/material.dart';

class StockHistoryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> history;

  const StockHistoryWidget({
    super.key,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (_, i) {
        final item = history[i];

        return ListTile(
          leading: Icon(
            item['type'] == 'IN'
                ? Icons.arrow_downward
                : Icons.arrow_upward,
            color: item['type'] == 'IN'
                ? Colors.green
                : Colors.red,
          ),
          title: Text(item['name']),
          subtitle: Text(item['date']),
          trailing: Text(item['type']),
        );
      },
    );
  }
}
