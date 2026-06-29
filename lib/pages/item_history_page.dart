import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../app_config.dart';
import '../model/stock_item.dart';

class ItemHistoryPage extends StatefulWidget {
  final StockItem item;
  const ItemHistoryPage({super.key, required this.item});

  @override
  State<ItemHistoryPage> createState() => _ItemHistoryPageState();
}

class _ItemHistoryPageState extends State<ItemHistoryPage> {
  List<dynamic> _historyList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSpecificHistory();
  }

  Future<void> _fetchSpecificHistory() async {
    setState(() => _isLoading = true);
    try {
      // Tembak API laptop dengan membawa parameter id_barang jirr
      var url = Uri.parse("${AppConfig.baseUrl}/get_item_history.php?id_barang=${widget.item.idBarang}");
      var response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _historyList = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Eror Log Barang jirr: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Riwayat Mutasi", style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(widget.item.name, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSpecificHistory,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _historyList.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          itemCount: _historyList.length,
          itemBuilder: (context, index) {
            final log = _historyList[index];
            String typeStr = log['type'].toString().toUpperCase();
            bool isMasuk = typeStr.contains('MASUK') || typeStr.contains('BARU');
            Color themeColor = isMasuk ? Colors.green : Colors.red;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 3))
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: themeColor.withOpacity(0.1),
                    child: Icon(isMasuk ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded, color: themeColor, size: 22),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(typeStr, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: themeColor)),
                        const SizedBox(height: 2),
                        Text("Stok: ${log['qty_before'] ?? '0'} ➔ ${log['qty_after'] ?? '0'}", style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
                        if (log['description'] != null && log['description'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text("📝 Catatan: ${log['description']}", style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[700], fontStyle: FontStyle.italic)),
                          ),
                        const SizedBox(height: 4),
                        Text(log['date'].toString(), style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text(
                    "${isMasuk ? '+' : '-'}${log['qty']}",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: themeColor),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text("Aset ini belum pernah dimutasi cok!", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}