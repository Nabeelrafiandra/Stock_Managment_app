<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

// 🟢 FIX UTAMA: Panggil file koneksi database port 3307 yang udah kita benerin tadi jirr!
// Variabel koneksinya adalah $koneksi (sesuai isi file koneksi.php kamu cok)
include 'koneksi.php';

// Menangkap input dari Flutter
$user = isset($_POST['username']) ? $_POST['username'] : '';
$pass = isset($_POST['password']) ? $_POST['password'] : '';

if (empty($user) || empty($pass)) {
    echo json_encode(["status" => "error", "message" => "Username dan password wajib diisi braay!"]);
    exit();
}

// Cek kecocokan data ke tabel users
$sql = "SELECT * FROM users WHERE username = '$user' AND password = '$pass'";
$result = mysqli_query($koneksi, $sql); // Menggunakan fungsi mysqli yang sama dengan get_items.php

if ($result && mysqli_num_rows($result) > 0) {
    $row = mysqli_fetch_assoc($result);
    
    // Kirim respon sukses beserta role-nya ke Flutter HP cok
    echo json_encode([
        "status" => "success",
        "message" => "Login berhasil jirr!",
        "role" => $row['role'] // Mengambil data role pas sesuai 3 kolom kamu (admin/staff)
    ]);
} else {
    echo json_encode(["status" => "error", "message" => "Username atau password salah cok!"]);
}

// Tutup koneksi jirr
mysqli_close($koneksi);
?>