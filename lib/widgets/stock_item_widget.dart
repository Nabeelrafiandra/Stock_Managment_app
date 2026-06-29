import 'dart:io';
import 'package:flutter/material.dart';

class StockItemWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onAdd;
  final VoidCallback onReduce;
  final VoidCallback onDelete;

  const StockItemWidget({
    super.key,
    required this.item,
    required this.onAdd,
    required this.onReduce,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(12)),
            child: item['image_path'] != null && item['image_path'].isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(item['image_path']), fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: Colors.grey)),
            )
                : const Icon(Icons.inventory_2, color: Colors.blueGrey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'] ?? 'Tanpa Nama', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    Flexible(child: Text("Kode: ${item['code']}", style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis)),
                    if (item['qr_path'] != null && item['qr_path'].isNotEmpty)
                      const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.qr_code, size: 14, color: Colors.blueAccent)),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.remove_circle_outline, color: Colors.orange, size: 22), onPressed: onReduce),
              Text("${item['qty']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 22), onPressed: onAdd),
              IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22), onPressed: onDelete),
            ],
          ),
        ],
      ),
    );
  }
}