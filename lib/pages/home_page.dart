import 'dart:convert'; // Wajib untuk handle JSON internet
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http; // Panggil HTTP package
import 'package:stock_app/pages/catalog_page.dart';
import 'package:stock_app/pages/input_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_config.dart'; // Panggil basis URL Ngrok kamu jirr

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int totalItem = 0;
  int totalStock = 0;
  List<dynamic> recentHistory = []; // Diubah jadi List<dynamic> dari JSON
  String _userRole = 'viewer';
  bool _isLoading = true; // Tambahan efek loading biar mantap braay

  @override
  void initState() {
    super.initState();
    _checkRole();
    loadDashboardData(); // Ganti ke fungsi penarik data internet cok
  }

  void _checkRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('user_role') ?? 'viewer';
    });
  }

  void _navigateToInputPage() async {
    if (_userRole == 'admin') {
      await Navigator.push(context, MaterialPageRoute(builder: (c) => const InputPage()));
      loadDashboardData(); // Refresh otomatis pas balik dari input page jirr
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Akses Ditolak! Khusus Admin Kantor jirr"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Tarik total barang & log aktivitas langsung dari MySQL Laptop
  Future<void> loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1. Ambil data barang untuk menghitung statistik cok
      var urlItems = Uri.parse("${AppConfig.baseUrl}/get_items.php");
      var responseItems = await http.get(urlItems);

      // 2. Ambil data riwayat aktivitas (bikin file get_history.php di htdocs jirr)
      var urlHistory = Uri.parse("${AppConfig.baseUrl}/get_history.php");
      var responseHistory = await http.get(urlHistory);

      if (responseItems.statusCode == 200) {
        List<dynamic> itemsData = json.decode(responseItems.body);

        int hitungStock = 0;
        for (var item in itemsData) {
          hitungStock += int.parse(item['qty'].toString());
        }

        List<dynamic> historyData = [];
        if (responseHistory.statusCode == 200) {
          historyData = json.decode(responseHistory.body);
        }

        if (mounted) {
          setState(() {
            totalItem = itemsData.length; // Hitung total baris jenis barang
            totalStock = hitungStock;    // Hitung akumulasi kuantitas stok
            recentHistory = historyData; // Masukkan list log aktivitas terbaru
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        print("Eror Dashboard jirr: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text("Stock Management", style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: loadDashboardData, // Usap layar ke bawah buat sinkron data baru cok
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column( // 🟢 FIX UTAMA: Ganti ListView terluar jadi Column biar dashboard atas statis terkunci jirr!
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _userRole == 'admin' ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Status Akses: ${_userRole.toUpperCase()}",
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _userRole == 'admin' ? Colors.blue : Colors.orange
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(child: _buildStatCard("Jenis Barang", "$totalItem", Icons.inventory_2_rounded, const Color(0xFF4A90E2))),
                  const SizedBox(width: 15),
                  Expanded(child: _buildStatCard("Total Stok", "$totalStock", Icons.analytics_rounded, const Color(0xFF50C878))),
                ],
              ),
              const SizedBox(height: 20),
              Text("Menu Utama", style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black54)),
              const SizedBox(height: 10),

              _buildMenuCard(
                  "Scan / Input Barang",
                  "Kelola stok masuk & keluar",
                  Icons.qr_code_scanner_rounded,
                  _userRole == 'admin' ? const Color(0xFF50C878) : Colors.grey,
                  _navigateToInputPage
              ),

              _buildMenuCard("Lihat Katalog", "Cek detail & ketersediaan stok", Icons.grid_view_rounded, const Color(0xFF4A90E2), () async {
                await Navigator.push(context, MaterialPageRoute(builder: (c) => const CatalogPage()));
                loadDashboardData(); // Refresh statistik pas balik dari katalog braay
              }),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Aktivitas Terkini", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("History", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 10),

              // =========================================================================
              // 🟢 PANEL FIX AUTO-SCROLL SEPARATED JIRR (MENGUNCI TAMPILAN GUDANG)
              // =========================================================================
              Expanded( // ➔ Paksa sisa layar bawah dipakai penuh untuk panel history cok
                child: recentHistory.isEmpty
                    ? _buildEmptyHistory()
                    : ListView.builder( // ➔ Pakai builder biar ramah memori HP Ryzen kamu braay
                  physics: const BouncingScrollPhysics(), // Efek mantul pas di-scroll jirr
                  itemCount: recentHistory.length,
                  itemBuilder: (context, index) {
                    return _buildHistoryCard(recentHistory[index]);
                  },
                ),
              ),
              // =========================================================================
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(dynamic data) {
    String typeStr = data['type'].toString().toUpperCase();
    bool isMasuk = typeStr.contains('MASUK') || typeStr.contains('BARU');
    Color themeColor = isMasuk ? Colors.green : Colors.red;

    String qtyBefore = data['qty-before'] != null ? data['qty-before'].toString() : '0';
    String qtyAfter = data['qty-after'] != null ? data['qty-after'].toString() : '0';
    String dateStr = data['date'] != null && data['date'].toString().length >= 16
        ? data['date'].toString().substring(0, 16)
        : data['date'].toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: themeColor.withOpacity(0.1),
            child: Icon(isMasuk ? Icons.arrow_downward : Icons.arrow_upward, color: themeColor, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['item_name'].toString(), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                Text("Stok: $qtyBefore ➔ $qtyAfter", style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54)),
                Text(dateStr, style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                  "${isMasuk ? '+' : '-'}${data['qty']}",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: themeColor, fontSize: 16)
              ),
              Text(typeStr, style: GoogleFonts.poppins(fontSize: 8, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, color: Colors.grey[300], size: 50),
            const SizedBox(height: 10),
            Text("Belum ada aktivitas di database laptop braay", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15), // Dikecilkan dikit paddingnya biar muat simetris cok
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMenuCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: color, size: 24)),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}