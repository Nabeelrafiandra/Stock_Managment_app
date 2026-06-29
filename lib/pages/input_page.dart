import 'dart:io';
import 'dart:convert'; // Tambahan wajib untuk membaca respon JSON dari PHP
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Wajib untuk filter digits only agar mengunci input angka
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // Digunakan untuk scanning barcode fisik barang
import 'package:file_picker/file_picker.dart'; // 🟢 Solusi pengganti ImagePicker untuk scan dari galeri
import 'package:http/http.dart' as http;
import '../app_config.dart';
import '../model/stock_item.dart';

class InputPage extends StatefulWidget {
  final StockItem? itemToEdit;
  const InputPage({super.key, this.itemToEdit});

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  final TextEditingController idBarangCtrl = TextEditingController();
  final TextEditingController codeCtrl = TextEditingController();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController();
  final TextEditingController newCategoryCtrl = TextEditingController();

  // Controller penampung catatan deskripsi transaksi gudang
  final TextEditingController descriptionCtrl = TextEditingController();

  final MobileScannerController scannerController = MobileScannerController();

  String _statusText = "Masukkan data barang";
  bool _isNewItem = true;
  bool isAdding = true;

  // Daftar kategori dinamis gudang pakaian
  List<String> categories = ["ATK", "ALAT ELEKTRONIK", "DOKUMEN", "LAINNYA"];
  String? selectedCategory;

  // Variabel penampung stok asli dari database server
  int currentLaptopStock = 0;

  @override
  void initState() {
    super.initState();
    codeCtrl.addListener(_onCodeChanged);
    nameCtrl.addListener(_onNameChanged);

    // Nilai awal jumlah transaksi diatur ke angka 0
    qtyCtrl.text = "0";
    qtyCtrl.addListener(_onQtyChanged);

    if (widget.itemToEdit != null) {
      final item = widget.itemToEdit!;
      idBarangCtrl.text = item.idBarang;
      codeCtrl.text = item.code;
      nameCtrl.text = item.name;
      qtyCtrl.text = item.qty.toString();

      if (item.category != null && !categories.contains(item.category)) {
        categories.add(item.category!);
      }
      selectedCategory = categories.contains(item.category) ? item.category : null;

      _isNewItem = false;
      _statusText = "Mode Perbarui Data";
    }
  }

  @override
  void dispose() {
    idBarangCtrl.dispose();
    codeCtrl.dispose();
    nameCtrl.dispose();
    qtyCtrl.dispose();
    newCategoryCtrl.dispose();
    descriptionCtrl.dispose();
    scannerController.dispose();
    super.dispose();
  }

  void _onQtyChanged() {
    setState(() {});
  }

  Color _getThemeColor() {
    if (widget.itemToEdit != null) return Colors.orange;
    if (_isNewItem && isAdding) return Colors.blue;
    return isAdding ? Colors.green : Colors.redAccent;
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

  void _onNameChanged() async {
    if (widget.itemToEdit == null && !isAdding && codeCtrl.text.isEmpty && nameCtrl.text.isNotEmpty) {
      String nameSearch = nameCtrl.text.trim();
      try {
        var url = Uri.parse("${AppConfig.baseUrl}/get_fifo_item.php?name=${Uri.encodeComponent(nameSearch)}");
        var response = await http.get(url);

        if (response.statusCode == 200 && response.body.isNotEmpty) {
          var data = json.decode(response.body);
          if (data['status'] == 'success') {
            setState(() {
              codeCtrl.text = data['code'];
              _statusText = "FIFO: Mengambil stok terlama dari server";
            });
          }
        }
      } catch (e) {
        debugPrint("Error FIFO Server: $e");
      }
    }
  }

  void _onCodeChanged() async {
    if (widget.itemToEdit != null) return;

    String code = codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() {
        _statusText = "Masukkan kode barang";
        _isNewItem = true;
        selectedCategory = null;
        currentLaptopStock = 0;
        idBarangCtrl.clear();
        nameCtrl.clear();
        qtyCtrl.text = "0";
      });
      return;
    }

    try {
      var url = Uri.parse("${AppConfig.baseUrl}/check_item.php?code=$code");
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == 'exists') {
          String cat = data['category'] ?? "Umum";
          if (!categories.contains(cat)) {
            categories.add(cat);
          }
          setState(() {
            _statusText = isAdding ? "Barang Terdaftar (Stok akan ditambah)" : "Barang Terdaftar (Stok akan dikurangi)";
            _isNewItem = false;
            idBarangCtrl.text = data['id_barang'].toString();
            nameCtrl.text = data['name'].toString();
            selectedCategory = cat;
            currentLaptopStock = int.parse(data['qty'].toString());
            qtyCtrl.text = "0";
          });
          _showSnackBar("✅ Data ${data['name']} otomatis terisi", Colors.green);
        } else {
          setState(() {
            _statusText = "Barang Baru (Server MySQL)";
            _isNewItem = true;
            nameCtrl.clear();
            idBarangCtrl.clear();
            qtyCtrl.text = "0";
            currentLaptopStock = 0;
            selectedCategory = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        _statusText = "Gagal terhubung ke server!";
      });
    }
  }

  void _processStock() async {
    String idBarang = idBarangCtrl.text.trim();
    String code = codeCtrl.text.trim();
    String name = nameCtrl.text.trim();
    int qtyInput = int.tryParse(qtyCtrl.text) ?? 0;
    String category = selectedCategory ?? "Umum";
    String description = descriptionCtrl.text.trim();

    if (idBarang.isEmpty || code.isEmpty || name.isEmpty || qtyInput <= 0) {
      _showSnackBar("Lengkapi semua data dan jumlah dengan benar.", Colors.red);
      return;
    }

    if (!isAdding && !_isNewItem && qtyInput > currentLaptopStock) {
      _showSnackBar("❌ Gagal! Stok di database hanya tersedia $currentLaptopStock Pcs, tidak dapat mengeluarkan $qtyInput Pcs.", Colors.red);
      return;
    }

    _showSnackBar("Menyinkronkan data ke database laptop...", _getThemeColor());

    try {
      if (widget.itemToEdit != null) {
        var url = Uri.parse("${AppConfig.baseUrl}/update_item.php");
        var response = await http.post(url, body: {
          "id_barang": idBarang,
          "code": code,
          "name": name,
          "qty": qtyInput.toString(),
          "category": category,
          "type_history": "EDIT DATA",
          "qty_before": widget.itemToEdit!.qty.toString(),
          "qty_after": qtyInput.toString(),
          "description": description
        });

        if (response.statusCode == 200 && response.body.trim() == "Sukses") {
          _showSnackBar("✅ Data katalog berhasil diperbarui di database.", Colors.green);
          if (mounted) Navigator.pop(context);
        } else {
          _showSnackBar("❌ Gagal memperbarui data: ${response.body}", Colors.red);
        }
        return;
      }

      int totalStokAkhir = _isNewItem
          ? qtyInput
          : (isAdding ? (currentLaptopStock + qtyInput) : (currentLaptopStock - qtyInput));

      var url = Uri.parse("${AppConfig.baseUrl}/insert_item.php");
      var request = http.MultipartRequest("POST", url);

      request.fields["id_barang"] = idBarang;
      request.fields["code"] = code;
      request.fields["name"] = name;
      request.fields["qty"] = totalStokAkhir.toString();
      request.fields["category"] = category;
      request.fields["description"] = description;

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 && response.body.trim() == "Sukses") {
        _showSnackBar(
            _isNewItem
                ? "✅ Barang baru berhasil disimpan ke database."
                : (isAdding ? "✅ Stok berhasil ditambah di database." : "✅ Stok berhasil dikurangi di database."),
            isAdding ? Colors.green : Colors.orange
        );

        idBarangCtrl.clear();
        codeCtrl.clear();
        nameCtrl.clear();
        descriptionCtrl.clear();
        qtyCtrl.text = "0";
        setState(() {
          selectedCategory = null;
          _statusText = "Masukkan data barang";
          _isNewItem = true;
          currentLaptopStock = 0;
        });
        FocusScope.of(context).unfocus();
      } else {
        _showSnackBar("❌ Gagal Server: ${response.body}", Colors.red);
      }

    } catch (e) {
      _showSnackBar("❌ Koneksi terputus. Pastikan server Ngrok Anda aktif. Error: $e", Colors.red);
    }
  }

  void _generateOnlyCode() {
    if (codeCtrl.text.isEmpty) {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
      setState(() {
        codeCtrl.text = "$timestamp";
      });
      _showSnackBar("⚡ Kode Teks $timestamp Berhasil Dibuat!", Colors.blue);
    } else {
      _showSnackBar("⚠️ Kode Barcode sudah terisi.", Colors.orange);
    }
  }

  void _openScanner() async {
    try {
      await scannerController.start();
    } catch (e) {
      await scannerController.stop();
      await scannerController.start();
    }

    if (!mounted) return;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
                color: Color(0xFF1E1E24),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30))
            ),
            child: Column(children: [
              const SizedBox(height: 15),
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(10))),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text("Scan Label Barang", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                IconButton(
                    icon: const Icon(Icons.photo_library_rounded, color: Colors.orange, size: 26),
                    onPressed: () async {
                      await scannerController.stop();
                      if (context.mounted) Navigator.pop(context);
                      _scanFromGallery();
                    }
                )
              ])),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        MobileScanner(
                            controller: scannerController,
                            onDetect: (capture) async {
                              final code = capture.barcodes.first.rawValue ?? "";
                              if (code.isNotEmpty) {
                                codeCtrl.text = code;
                                await scannerController.stop();
                                if (context.mounted) Navigator.pop(context);
                              }
                            }
                        ),
                        ColorFiltered(
                          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.srcOut),
                          child: Stack(
                            children: [
                              Container(color: Colors.transparent),
                              Center(child: Container(width: 260, height: 160, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)))),
                            ],
                          ),
                        ),
                        Center(child: Container(width: 260, height: 160, decoration: BoxDecoration(border: Border.all(color: Colors.white30, width: 1), borderRadius: BorderRadius.circular(20)))),
                        Center(
                          child: SizedBox(
                            width: 260,
                            height: 160,
                            child: Stack(
                              children: [
                                Positioned(top: 0, left: 0, child: Container(width: 20, height: 20, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.orange, width: 4), left: BorderSide(color: Colors.orange, width: 4)), borderRadius: BorderRadius.only(topLeft: Radius.circular(12))))),
                                Positioned(top: 0, right: 0, child: Container(width: 20, height: 20, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.orange, width: 4), right: BorderSide(color: Colors.orange, width: 4)), borderRadius: BorderRadius.only(topRight: Radius.circular(12))))),
                                Positioned(bottom: 0, left: 0, child: Container(width: 20, height: 20, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.orange, width: 4), left: BorderSide(color: Colors.orange, width: 4)), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12))))),
                                Positioned(bottom: 0, right: 0, child: Container(width: 20, height: 20, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.orange, width: 4), right: BorderSide(color: Colors.orange, width: 4)), borderRadius: BorderRadius.only(bottomRight: Radius.circular(12))))),
                              ],
                            ),
                          ),
                        ),
                        const ScannerLaserLineAnimation(),
                        Positioned(
                          bottom: 30,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
                            child: Text("Sejajarkan Kode Batang / QR di dalam kotak", style: GoogleFonts.poppins(color: Colors.white, fontSize: 11)),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              )
            ])
        )
    ).then((_) async {
      await scannerController.stop();
    });
  }

  Future<void> _scanFromGallery() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        final barcodeFound = await scannerController.analyzeImage(result.files.single.path!);
        if (barcodeFound != null && barcodeFound.barcodes.isNotEmpty) {
          final String code = barcodeFound.barcodes.first.rawValue ?? "";
          if (code.isNotEmpty) {
            setState(() => codeCtrl.text = code);
            _showSnackBar("✅ Kode $code ditemukan", Colors.green);
          }
        } else {
          _showSnackBar("❌ Tidak ditemukan kode di foto tersebut", Colors.orange);
        }
      }
    } catch (e) {
      _showSnackBar("❌ Gagal membaca gambar: $e", Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.poppins()), backgroundColor: color, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
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
    bool isEditMode = widget.itemToEdit != null;

    int currentInputValue = int.tryParse(qtyCtrl.text.trim()) ?? 0;
    bool isInputValid = currentInputValue > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Text(
              isEditMode ? "Edit Informasi Barang" : (isAdding ? "Barang Masuk" : "Barang Keluar"),
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
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(_statusText, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: themeColor, fontSize: 13))),
            ),

            if (!isEditMode) ...[
              AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                  child: Row(
                      children: [
                        Expanded(child: _buildToggleButton("MASUK", isAdding, Colors.green, () {
                          setState(() => isAdding = true);
                          _onCodeChanged();
                        })),
                        Expanded(child: _buildToggleButton("KELUAR", !isAdding, Colors.redAccent, () {
                          setState(() => isAdding = false);
                          _onCodeChanged();
                        }))
                      ]
                  )
              ),
              const SizedBox(height: 25),
            ],

            TextField(
              controller: idBarangCtrl,
              enabled: !isEditMode && _isNewItem,
              decoration: _customInputDecoration("ID Barang (Nomor Aset)", Icons.fingerprint_rounded, enabled: !isEditMode && _isNewItem),
            ),
            const SizedBox(height: 20),

            TextField(
                controller: codeCtrl,
                enabled: !isEditMode,
                decoration: _customInputDecoration(
                    "Kode Barcode/QR",
                    Icons.qr_code_rounded,
                    enabled: !isEditMode,
                    suffixIcon: isEditMode
                        ? null
                        : (!isAdding
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: Icon(Icons.qr_code_scanner_rounded, color: themeColor), onPressed: _openScanner)
                      ],
                    )
                        : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: Icon(Icons.auto_fix_high, color: themeColor), onPressed: _generateOnlyCode),
                          IconButton(icon: Icon(Icons.qr_code_scanner_rounded, color: themeColor), onPressed: _openScanner)
                        ]
                    )
                    )
                )
            ),
            const SizedBox(height: 20),

            TextField(
                controller: nameCtrl,
                enabled: !isEditMode && _isNewItem,
                decoration: _customInputDecoration("Nama Barang", Icons.inventory_2_rounded, enabled: !isEditMode && _isNewItem)
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: _customInputDecoration("Kategori Barang", Icons.category_rounded, enabled: !isEditMode && _isNewItem),
                      items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: GoogleFonts.poppins()))).toList(),
                      onChanged: (!isEditMode && _isNewItem) ? (val) => setState(() => selectedCategory = val) : null,
                      icon: Icon(Icons.arrow_drop_down_circle_outlined, color: (!isEditMode && _isNewItem) ? themeColor : Colors.grey[400])
                  ),
                ),
                if (!isEditMode && _isNewItem) ...[
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
              ],
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: themeColor.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditMode ? "Jumlah Stok" : (isAdding ? "Jumlah Tambah" : "Jumlah Keluar"),
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          int currentVal = int.tryParse(qtyCtrl.text) ?? 0;
                          if (currentVal > 0) {
                            qtyCtrl.text = (currentVal - 1).toString();
                            qtyCtrl.selection = TextSelection.fromPosition(TextPosition(offset: qtyCtrl.text.length));
                            setState(() {});
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.remove, color: themeColor, size: 20),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            if (value.startsWith('0') && value.length > 1) {
                              qtyCtrl.text = int.parse(value).toString();
                              qtyCtrl.selection = TextSelection.fromPosition(TextPosition(offset: qtyCtrl.text.length));
                            }
                            setState(() {});
                          },
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          int currentVal = int.tryParse(qtyCtrl.text) ?? 0;

                          if (!isAdding && !_isNewItem && currentVal >= currentLaptopStock) {
                            _showSnackBar("⚠️ Jumlah mencapai batas stok asli di database.", Colors.orange);
                            return;
                          }

                          qtyCtrl.text = (currentVal + 1).toString();
                          qtyCtrl.selection = TextSelection.fromPosition(TextPosition(offset: qtyCtrl.text.length));
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.add, color: themeColor, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Builder(
              builder: (context) {
                int inputQty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                int stokSekarang = _isNewItem ? 0 : currentLaptopStock;

                if (inputQty == 0 || isEditMode) return const SizedBox.shrink();

                int stokAkhir = isAdding ? (stokSekarang + inputQty) : (stokSekarang - inputQty);

                return Container(
                  margin: const EdgeInsets.only(top: 15, bottom: 5),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: isAdding ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isAdding ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Simulasi Perubahan Stok:",
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                "$stokSekarang",
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isAdding ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isAdding ? Icons.add : Icons.remove,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "$inputQty",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isAdding ? Colors.green[700] : Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Stok Akhir:",
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$stokAkhir",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: stokAkhir < 0 ? Colors.red : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
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

            Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
                child: ElevatedButton(
                    onPressed: isInputValid ? _processStock : null,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: isInputValid ? themeColor : Colors.grey[300],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))
                    ),
                    child: Text(
                        isEditMode ? "SIMPAN PERUBAHAN" : (_isNewItem ? "DAFTARKAN BARANG" : "KONFIRMASI STOK"),
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isInputValid ? Colors.white : Colors.grey[500]
                        )
                    )
                )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, Color activeColor, VoidCallback onTap) {
    return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(12)
            ),
            child: Center(
                child: Text(
                    text,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey[600]
                    )
                )
            )
        )
    );
  }
}

class ScannerLaserLineAnimation extends StatefulWidget {
  const ScannerLaserLineAnimation({super.key});

  @override
  State<ScannerLaserLineAnimation> createState() => _ScannerLaserLineAnimationState();
}

class _ScannerLaserLineAnimationState extends State<ScannerLaserLineAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -65.0, end: 65.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            width: 240,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.orange,
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.8),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}