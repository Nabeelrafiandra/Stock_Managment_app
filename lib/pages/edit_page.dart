import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../app_config.dart';
import '../model/stock_item.dart';

class EditPage extends StatefulWidget {
  final StockItem item;
  const EditPage({super.key, required this.item});

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  final TextEditingController idBarangCtrl = TextEditingController();
  final TextEditingController codeCtrl = TextEditingController();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController descriptionCtrl = TextEditingController();
  final TextEditingController newCategoryCtrl = TextEditingController();

  List<String> categories = ["ATK", "ALAT ELEKTRONIK", "DOKUMEN", "LAINNYA"];
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    // Memuat data awal dari item katalog yang dipilih
    idBarangCtrl.text = widget.item.idBarang;
    codeCtrl.text = widget.item.code;
    nameCtrl.text = widget.item.name;
    descriptionCtrl.text = widget.item.description ?? '';

    if (widget.item.category.isNotEmpty && !categories.contains(widget.item.category)) {
      categories.add(widget.item.category);
    }
    selectedCategory = categories.contains(widget.item.category) ? widget.item.category : null;
  }

  @override
  void dispose() {
    idBarangCtrl.dispose();
    codeCtrl.dispose();
    nameCtrl.dispose();
    descriptionCtrl.dispose();
    newCategoryCtrl.dispose();
    super.dispose();
  }

  Color _getThemeColor() {
    return Colors.blue; // Menggunakan aksen biru formal untuk mode edit data
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Tambah Kategori Baru", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: newCategoryCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: "Masukkan nama kategori (Contoh: FURNITUR)",
            hintStyle: GoogleFonts.poppins(fontSize: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              newCategoryCtrl.clear();
              Navigator.pop(context);
            },
            child: Text("Batal", style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              String newCat = newCategoryCtrl.text.trim();
              if (newCat.isNotEmpty) {
                if (!categories.contains(newCat)) {
                  setState(() {
                    categories.add(newCat);
                    selectedCategory = newCat;
                  });
                  newCategoryCtrl.clear();
                  Navigator.pop(context);
                  _showSnackBar("✅ Kategori $newCat berhasil ditambahkan", Colors.green);
                } else {
                  _showSnackBar("⚠️ Kategori tersebut sudah ada di daftar", Colors.orange);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getThemeColor(),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Tambah", style: GoogleFonts.poppins(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _updateItemData() async {
    String idBarang = idBarangCtrl.text.trim();
    String code = codeCtrl.text.trim();
    String name = nameCtrl.text.trim();
    String category = selectedCategory ?? "Umum";
    String description = descriptionCtrl.text.trim();

    if (name.isEmpty) {
      _showSnackBar("❌ Nama barang tidak boleh kosong.", Colors.red);
      return;
    }

    _showSnackBar("Menyimpan perubahan ke database laptop...", _getThemeColor());

    try {
      var url = Uri.parse("${AppConfig.baseUrl}/update_item.php");
      var response = await http.post(url, body: {
        "id_barang": idBarang,
        "code": code,
        "name": name,
        "qty": widget.item.qty.toString(), // Qty dikunci menggunakan nilai asli katalog
        "category": category,
        "type_history": "EDIT DATA",
        "qty_before": widget.item.qty.toString(),
        "qty_after": widget.item.qty.toString(),
        "description": description
      });

      if (response.statusCode == 200 && response.body.trim() == "Sukses") {
        _showSnackBar("✅ Data katalog berhasil diperbarui di database.", Colors.green);
        if (mounted) Navigator.pop(context);
      } else {
        _showSnackBar("❌ Gagal memperbarui data: ${response.body}", Colors.red);
      }
    } catch (e) {
      _showSnackBar("❌ Koneksi terputus. Gagal memperbarui database laptop. Error: $e", Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
    ));
  }

  InputDecoration _customInputDecoration(String label, IconData icon, {Widget? suffixIcon, bool enabled = true}) {
    Color themeColor = _getThemeColor();
    return InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 14, color: enabled ? Colors.grey[600] : Colors.grey[400]),
        prefixIcon: Icon(icon, color: enabled ? themeColor : Colors.grey[400]),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: themeColor.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: themeColor, width: 2)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[300]!))
    );
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor = _getThemeColor();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Text(
              "Edit Informasi Barang",
              style: GoogleFonts.poppins(color: themeColor, fontWeight: FontWeight.bold)
          ),
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20), onPressed: () => Navigator.pop(context))
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 25),
              decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text("Ubah data spesifikasi katalog aset", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: themeColor, fontSize: 13))),
            ),

            // 🔒 ID BARANG (DISABLED - TIDAK BISA DIEDIT)
            TextField(
              controller: idBarangCtrl,
              enabled: false,
              decoration: _customInputDecoration("ID Barang (Nomor Aset Terkunci)", Icons.fingerprint_rounded, enabled: false),
            ),
            const SizedBox(height: 20),

            // 🔒 KODE BARCODE (DISABLED - TIDAK BISA DIEDIT)
            TextField(
                controller: codeCtrl,
                enabled: false,
                decoration: _customInputDecoration("Kode Barcode/QR (Terkunci)", Icons.qr_code_rounded, enabled: false)
            ),
            const SizedBox(height: 20),

            // 🔓 NAMA BARANG (ENABLED - BISA DIEDIT)
            TextField(
                controller: nameCtrl,
                enabled: true,
                decoration: _customInputDecoration("Nama Barang", Icons.inventory_2_rounded, enabled: true)
            ),
            const SizedBox(height: 20),

            // 🔓 KATEGORI BARANG DYNAMIC (ENABLED - BISA DIEDIT & BISA TAMBAH BARU)
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: _customInputDecoration("Kategori Barang", Icons.category_rounded, enabled: true),
                      items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: GoogleFonts.poppins()))).toList(),
                      onChanged: (val) => setState(() => selectedCategory = val),
                      icon: Icon(Icons.arrow_drop_down_circle_outlined, color: themeColor)
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 58,
                  width: 58,
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: themeColor.withOpacity(0.2)),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.add_circle_rounded, color: themeColor, size: 30),
                    onPressed: _showAddCategoryDialog,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 🔓 DESKRIPSI CATATAN (ENABLED - BISA DIEDIT)
            TextField(
              controller: descriptionCtrl,
              maxLines: 3,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.sentences,
              decoration: _customInputDecoration(
                  "Deskripsi Transaksi / Catatan Gudang",
                  Icons.description_rounded
              ),
            ),
            const SizedBox(height: 40),

            // BUTTON ACTION
            Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
                child: ElevatedButton(
                    onPressed: _updateItemData,
                    style: ElevatedButton.styleFrom(backgroundColor: themeColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                    child: Text(
                        "SIMPAN PERUBAHAN KATALOG",
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                    )
                )
            ),
          ],
        ),
      ),
    );
  }
}