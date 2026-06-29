import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import package http untuk koneksi ke XAMPP
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart'; // Halaman untuk Admin (Bisa Input/Edit)
import 'catalog_page.dart'; // Halaman untuk Viewer (Hanya Lihat)
import 'register_page.dart';
import '../app_config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController userCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  bool _isObscure = true;
  bool _isLoading = false; // Variabel penanda loading server

  void _handleLogin() async {
    String username = userCtrl.text.trim();
    String password = passCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar("Mohon isi semua field", Colors.orange);
      return;
    }

    // Aktifkan indikator loading putar
    setState(() {
      _isLoading = true;
    });

    // Menggunakan IP Wi-Fi yang sudah sukses terhubung kemarin
    String url = "https://truck-rockiness-customize.ngrok-free.dev/stock_api/login.php";

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          "username": username,
          "password": password,
        },
      ).timeout(const Duration(seconds: 10)); // Batasi waktu tunggu 10 detik

      // Matikan indikator loading setelah mendapat respon dari server
      if (mounted) setState(() => _isLoading = false);

      // Jika koneksi ke server Apache XAMPP sukses (status 200)
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          String role = data['role']; // Mengambil role dari database MySQL ('admin' / 'viewer')

          // Simpan ke SharedPreferences untuk pengecekan hak akses di halaman tujuan
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_role', role);

          if (mounted) {
            _showSnackBar("Login Berhasil sebagai $role", Colors.green);

            // FIX: Menggunakan pushAndRemoveUntil untuk membersihkan stack riwayat halaman
            if (role == 'admin') {
              // Jika admin, arahkan ke InputPage dan hapus halaman login dari riwayat
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomePage()),
                    (route) => false,
              );
            } else {
              // Jika viewer, arahkan ke CatalogPage dan hapus halaman login dari riwayat
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomePage()),
                    (route) => false,
              );
            }
          }
        } else {
          // Menampilkan pesan gagal dari API PHP (misal: "Username atau Password salah")
          _showSnackBar(data['message'], Colors.red);
        }
      } else {
        _showSnackBar("Gagal terhubung ke server XAMPP (Status: ${response.statusCode})", Colors.red);
      }
    } catch (e) {
      // Matikan loading jika terjadi kegagalan jaringan/firewall block
      if (mounted) setState(() => _isLoading = false);

      _showSnackBar("Tidak dapat menjangkau server. Pastikan XAMPP aktif & IP benar!", Colors.red);
      print("Login Error: $e");
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_person, size: 80, color: Colors.blue),
              const SizedBox(height: 16),
              const Text("DISPAREKRAF STOCK MANAGMENT", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
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
              const SizedBox(height: 24),

              // TOMBOL MASUK DENGAN KONDISI LOADING
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin, // Nonaktifkan tombol jika sedang loading
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white) // Animasi putar loading
                      : const Text("MASUK", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 15),

              // TOMBOL MENUJU REGISTRASI
              TextButton(
                onPressed: _isLoading ? null : () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
                },
                child: const Text("Belum punya akun? Daftar di sini"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}