class StockItem {
  final String idBarang;
  final String code;
  final String name;
  final int qty;
  final String category;
  final String? imagePath;
  final String? dateIn;     // Menyimpan riwayat tanggal & jam masuk terakhir
  final String? dateOut;    // Menyimpan riwayat tanggal & jam keluar terakhir
  final String? description;

  StockItem({
    required this.idBarang,
    required this.code,
    required this.name,
    required this.qty,
    required this.category,
    this.imagePath,
    this.dateIn,
    this.dateOut,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_barang': idBarang,
      'code': code,
      'name': name,
      'qty': qty,
      'category': category,
      'image_path': imagePath,
      'date_in': dateIn,
      'date_out': dateOut,
      'description': description,
    };
  }

  factory StockItem.fromMap(Map<String, dynamic> map) {
    return StockItem(
      idBarang: map['id_barang']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      qty: int.tryParse(map['qty'].toString()) ?? 0,
      category: map['category']?.toString() ?? 'Umum',
      imagePath: map['image_path']?.toString(),
      // Memetakan alias data subquery dari backend PHP
      dateIn: map['terakhir_masuk']?.toString() ?? map['date_in']?.toString() ?? '-',
      dateOut: map['terakhir_keluar']?.toString() ?? map['date_out']?.toString() ?? '-',
      description: map['description']?.toString() ?? '',
    );
  }
}