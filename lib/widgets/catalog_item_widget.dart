import 'dart:io';
import 'package:flutter/material.dart';

class CatalogItemWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTapEdit;

  const CatalogItemWidget({
    super.key,
    required this.item,
    required this.onTapEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: item['image_path'] != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(item['image_path']),
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
        )
            : const Icon(Icons.inventory, size: 40),

        title: Text(item['name'],
            style: const TextStyle(fontWeight: FontWeight.bold)),

        subtitle: Text("Kode: ${item['code']}"),

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item['qty'].toString(),
              style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onTapEdit,
            ),
          ],
        ),
      ),
    );
  }
}
