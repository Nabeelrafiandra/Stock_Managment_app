import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:stock_app/pages/edit_page.dart';
import 'package:stock_app/pages/item_history_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:gal/gal.dart';

import '../app_config.dart';
import 'package:stock_app/model/stock_item.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  List<StockItem> allItems = [];
  List<StockItem> filteredItems = [];
  String searchQuery = "";
  String selectedCategory = "Semua";
  bool isLoading = true;

  List<String> categories = ["Semua"];
  String _userRole = "";

  final GlobalKey _barcodeKey = GlobalKey();
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkUserRoleAndLoad();
  }

  Future<void> _checkUserRoleAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    String savedRole = prefs.getString('role') ?? prefs.getString('user_role') ?? 'viewer';
    setState(() {
      _userRole = savedRole.toLowerCase().trim();
    });
    refreshData();
  }

  Future<void> refreshData() async {
    setState(() => isLoading = true);
    try {
      var url = Uri.parse("${AppConfig.baseUrl}/get_items.php");
      var response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> responseData = json.decode(response.body);

        List<StockItem> fetchedItems = responseData.map((jsonItem) {
          return StockItem.fromMap(jsonItem);
        }).toList();

        List<String> dynamicCategories = ["Semua"];
        for (var item in fetchedItems) {
          if (item.category.trim().isNotEmpty && !dynamicCategories.contains(item.category)) {
            dynamicCategories.add(item.category);
          }
        }

        setState(() {
          allItems = fetchedItems;
          categories = dynamicCategories;
          isLoading = false;
          _applyFilter();
        });
      } else {
        setState(() => isLoading = false);
        _showSnackBar("❌ Server menolak permintaan data katalog", Colors.red);
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar("❌ Gagal terhubung ke database cloud server!", Colors.red);
    }
  }

  void _applyFilter() {
    setState(() {
      filteredItems = allItems.where((item) {
        bool matchSearch = item.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            item.idBarang.toLowerCase().contains(searchQuery.toLowerCase());
        bool matchCategory = selectedCategory == "Semua" || item.category == selectedCategory;
        return matchSearch && matchCategory;
      }).toList();
    });
  }

  Future<void> _exportToCSV() async {
    _showSnackBar("⏳ Mengambil data history dari server...", Colors.blue);

    try {
      var url = Uri.parse("${AppConfig.baseUrl}/get_history.php");
      var response = await http.get(url);

      if (response.statusCode != 200) {
        _showSnackBar("❌ Gagal mengambil data history dari server!", Colors.red);
        return;
      }

      if (response.body.trim().startsWith("<!DOCTYPE") || response.body.trim().startsWith("<html")) {
        _showSnackBar("❌ Gagal: Server mengembalikan dokumen HTML error (Cek file get_history.php)!", Colors.red);
        return;
      }

      List<dynamic> historyData = json.decode(response.body);

      if (historyData.isEmpty) {
        _showSnackBar("❌ Gagal: Tabel riwayat transaksi masih kosong!", Colors.orange);
        return;
      }

      List<List<dynamic>> csvRows = [
        ["No", "Nama Barang", "Tipe Transaksi", "Jumlah (Qty)", "Stok Sebelum", "Stok Sesudah", "Catatan/Deskripsi", "Tanggal & Waktu"],
      ];

      for (int i = 0; i < historyData.length; i++) {
        var row = historyData[i];
        csvRows.add([
          i + 1,
          row['item_name'] ?? '-',
          row['type'] ?? '-',
          row['qty'] ?? 0,
          row['qty-before'] ?? 0,
          row['qty-after'] ?? 0,
          row['description'] ?? '-',
          row['date'] ?? '-',
        ]);
      }

      String csvString = const ListToCsvConverter().convert(csvRows);

      final directory = await getTemporaryDirectory();
      final filePath = "${directory.path}/Log_History_Gudang_Pakaian.csv";
      final file = File(filePath);
      await file.writeAsString(csvString);

      await Share.shareXFiles(
          [XFile(filePath)],
          text: 'Ekspor Log Riwayat Transaksi Barang Keluar-Masuk Gudang Pakaian'
      );
    } catch (e) {
      _showSnackBar("❌ Gagal memproses ekspor file CSV history: $e", Colors.red);
    }
  }

  // 🟢 REVISI FIX: Format 5 Kolom (ID Barang, Kode, Nama, Kategori, Qty)
  Future<void> _importFromCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
      if (result == null || result.files.single.path == null) {
        _showSnackBar("⚠️ Pemilihan file CSV dibatalkan", Colors.orange);
        return;
      }

      setState(() => isLoading = true);
      final file = File(result.files.single.path!);
      final csvString = await file.readAsString();

      List<List<dynamic>> fields = const CsvToListConverter().convert(csvString);
      if (fields.length <= 1) {
        _showSnackBar("❌ File CSV kosong atau strukturnya salah!", Colors.red);
        setState(() => isLoading = false);
        return;
      }

      List<Map<String, dynamic>> uploadList = [];
      for (int i = 1; i < fields.length; i++) {
        // Memastikan baris data memiliki minimal 5 kolom penuh
        if (fields[i].length < 5) continue;

        uploadList.add({
          "id_barang": fields[i][0].toString().trim(),
          "code": fields[i][1].toString().trim(),
          "name": fields[i][2].toString().trim(),
          "category": fields[i][3].toString().trim(),
          "qty": int.tryParse(fields[i][4].toString()) ?? 0,
        });
      }

      var url = Uri.parse("${AppConfig.baseUrl}/import_csv.php");
      var response = await http.post(url, headers: {"Content-Type": "application/json"}, body: json.encode(uploadList));

      if (response.body.trim().startsWith("<!DOCTYPE") || response.body.trim().startsWith("<html")) {
        _showSnackBar("❌ Gagal: Backend import_csv.php eror / mengembalikan HTML!", Colors.red);
        setState(() => isLoading = false);
        return;
      }

      var resultJson = json.decode(response.body);

      if (response.statusCode == 200 && resultJson['status'] == "Sukses") {
        _showSnackBar("✅ ${resultJson['message']}", Colors.green);
        refreshData();
      } else {
        _showSnackBar("❌ Gagal Import: ${resultJson['message']}", Colors.red);
        setState(() => isLoading = false);
      }
    } catch (e) {
      _showSnackBar("❌ Eror pemrosesan CSV: $e", Colors.red);
      setState(() => isLoading = false);
    }
  }

  Future<void> _downloadLabelImage(GlobalKey key, String fileName) async {
    _showSnackBar("Memproses penyimpanan gambar...", Colors.orange);
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      RenderRepaintBoundary boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 4.0);
      var byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      var pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/$fileName.png').create();
      await file.writeAsBytes(pngBytes);

      await Gal.putImage(file.path);
      _showSnackBar("✅ Gambar sukses disimpan di galeri foto HP!", Colors.green);
    } catch (e) {
      _showSnackBar("❌ Gagal mendownload gambar label: $e", Colors.red);
    }
  }

  void _showBarcodePrintDialog(StockItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Text(item.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
              Text("ID Aset: ${item.idBarang} | Kode: ${item.code}", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]), textAlign: TextAlign.center),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      RepaintBoundary(
                        key: _barcodeKey,
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(10),
                          width: 140,
                          height: 90,
                          child: Center(
                            child: BarcodeWidget(
                              barcode: Barcode.code128(),
                              data: item.code,
                              drawText: false,
                              width: 130,
                              height: 60,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text("Format Barcode", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[700])),
                      const SizedBox(height: 8),
                      IconButton(
                        icon: const Icon(Icons.download_for_offline_rounded, color: Colors.teal, size: 28),
                        onPressed: () => _downloadLabelImage(_barcodeKey, "barcode_${item.code}"),
                      )
                    ],
                  ),
                  Column(
                    children: [
                      RepaintBoundary(
                        key: _qrKey,
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(10),
                          width: 140,
                          height: 90,
                          child: Center(
                            child: BarcodeWidget(
                              barcode: Barcode.qrCode(),
                              data: item.code,
                              width: 70,
                              height: 70,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text("Format QR Code", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[700])),
                      const SizedBox(height: 8),
                      IconButton(
                        icon: const Icon(Icons.download_for_offline_rounded, color: Colors.purple, size: 28),
                        onPressed: () => _downloadLabelImage(_qrKey, "qrcode_${item.code}"),
                      )
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text("TUTUP MONITOR", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _deleteItem(String idBarang, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Hapus Barang?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Apakah Anda yakin ingin menghapus $name ($idBarang) dari katalog?", style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Batal", style: GoogleFonts.poppins(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              try {
                var url = Uri.parse("${AppConfig.baseUrl}/delete_item.php");
                var response = await http.post(url, body: {"id_barang": idBarang});

                if (response.statusCode == 200 && response.body.trim() == "Sukses") {
                  if (mounted) {
                    Navigator.pop(context);
                    refreshData();
                    _showSnackBar("✅ Barang $name berhasil dihapus dari database", Colors.blue);
                  }
                } else {
                  _showSnackBar("❌ Gagal menghapus: ${response.body}", Colors.red);
                }
              } catch (e) {
                _showSnackBar("❌ Gagal terkoneksi ke server: $e", Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text("Hapus", style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.poppins()), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text("Katalog Barang", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (_userRole != 'viewer') ...[
            IconButton(icon: const Icon(Icons.file_download_rounded, color: Colors.teal), onPressed: _exportToCSV),
            IconButton(icon: const Icon(Icons.file_upload_rounded, color: Colors.orange), onPressed: _importFromCSV),
          ],
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.blue), onPressed: refreshData)
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) {
                    searchQuery = val;
                    _applyFilter();
                  },
                  decoration: InputDecoration(
                    hintText: "Cari Nama atau ID Barang...",
                    hintStyle: GoogleFonts.poppins(fontSize: 13),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      bool isSelected = selectedCategory == categories[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: FilterChip(
                          label: Text(categories[index]),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() {
                              selectedCategory = categories[index];
                              _applyFilter();
                            });
                          },
                          selectedColor: Colors.blue.withOpacity(0.2),
                          checkmarkColor: Colors.blue,
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isSelected ? Colors.blue : Colors.black54,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredItems.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: refreshData,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(filteredItems[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(StockItem item) {
    Color stockColor = Colors.green;
    if (item.qty < 5) stockColor = Colors.red;
    else if (item.qty < 10) stockColor = Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              ),
              child: Icon(Icons.inventory_2_outlined, color: Colors.grey[400], size: 32),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(item.category, style: GoogleFonts.poppins(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                        ),
                        Text(item.idBarang, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(item.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text("Kode: ${item.code}", style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 6),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(text: "Stok: ", style: GoogleFonts.poppins(color: Colors.black54, fontSize: 13)),
                              TextSpan(text: "${item.qty}", style: GoogleFonts.poppins(color: stockColor, fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildActionButton(Icons.history_rounded, Colors.orange, () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ItemHistoryPage(item: item),
                                    ),
                                  );
                                }),
                                const SizedBox(width: 6),
                                _buildActionButton(Icons.qr_code_scanner_rounded, Colors.purple, () => _showBarcodePrintDialog(item)),
                              ],
                            ),
                            if (_userRole != 'viewer') ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildActionButton(Icons.edit_note_rounded, Colors.blue, () async {
                                    await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => EditPage(item: item))
                                    );
                                    refreshData();
                                  }),
                                  const SizedBox(width: 6),
                                  _buildActionButton(Icons.delete_outline_rounded, Colors.redAccent, () => _deleteItem(item.idBarang, item.name)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text("Barang tidak ditemukan di database", style: GoogleFonts.poppins(color: Colors.grey)),
        ],
      ),
    );
  }
}