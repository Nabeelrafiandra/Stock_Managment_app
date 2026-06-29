import 'dart:convert'; // Diperlukan untuk jsonDecode
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import package http untuk koneksi ke XAMPP
import '../app_config.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController userCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  String selectedRole = 'viewer'; // Default role
  bool _isObscure = true;
  bool _isLoading = false; // TAMBAHAN: Variabel untuk penanda loading register

  void _handleRegister() async {
    String username = userCtrl.text.trim();
    String password = passCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar("Mohon lengkapi semua data", Colors.orange);
      return;
    }

    // Aktifkan loading putar
    setState(() {
      _isLoading = true;
    });

    // PENTING:
    String url = "https://truck-rockiness-customize.ngrok-free.dev/stock_api/register.php";

    try {
      // Mengirimkan data via POST ke script PHP di XAMPP
      final response = await http.post(
        Uri.parse(url),
        body: {
          "username": username,
          "password": password,
          "role": selectedRole,
        },
      ).timeout(const Duration(seconds: 10)); // Batasi waktu tunggu maksimal 10 detik

      // Matikan loading setelah mendapat respon server
      if (mounted) setState(() => _isLoading = false);

      // Jika server Apache merespon dengan sukses (status 200)
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          _showSnackBar("Registrasi Berhasil sebagai $selectedRole!", Colors.green);

          if (mounted) {
            Navigator.pop(context); // Kembali ke halaman Login otomatis
          }
        } else {
          // Menampilkan pesan gagal dari PHP (misal: "Username sudah terdaftar!")
          _showSnackBar(data['message'], Colors.red);
        }
      } else {
        // Membantu mendeteksi jika terjadi error 404 lagi
        _showSnackBar("Gagal terhubung ke server XAMPP (Status: ${response.statusCode})", Colors.red);
      }
    } catch (e) {
      // Matikan loading jika koneksi gagal total/firewall block
      if (mounted) setState(() => _isLoading = false);

      _showSnackBar("Tidak dapat menjangkau server. Pastikan XAMPP aktif!", Colors.red);
      print("Register Error: $e");
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Daftar Akun Baru")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.person_add, size: 80, color: Colors.purple),
            const SizedBox(height: 20),
            TextField(
              controller: userCtrl,
              decoration: const InputDecoration(labelText: "Username", prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passCtrl,
              obscureText: _isObscure,
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _isObscure = !_isObscure),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dropdown Pilihan Role
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(labelText: "Pilih Hak Akses (Role)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.gavel)),
              items: const [
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
              ],
              onChanged: _isLoading ? null : (val) { // Kunci dropdown jika sedang loading
                if (val != null) setState(() => selectedRole = val);
              },
            ),
            const SizedBox(height: 24),

            // TOMBOL DENGAN INDIKATOR LOADING PUTAR
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister, // Kunci tombol saat sedang loading
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white) // Animasi loading bulat
                    : const Text("DAFTAR SEKARANG", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}