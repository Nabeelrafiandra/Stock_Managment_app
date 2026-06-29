<?php
header('Content-Type: application/json; charset=utf-8');
include 'koneksi.php';

// 1. Tangkap data yang dikirim dari aplikasi Flutter HP jirr
$username = isset($_POST['username']) ? $_POST['username'] : '';
$password = isset($_POST['password']) ? $_POST['password'] : '';
$role     = isset($_POST['role']) ? $_POST['role'] : 'staff'; // Default jadi staff kalau gak diisi

// 2. Validasi biar gak ada data kosong yang masuk cok
if (empty($username) || empty($password)) {
    echo json_encode([
        "status" => "error",
        "message" => "Username dan password wajib diisi braay!"
    ]);
    exit();
}

// 3. Masukkan data PAS sesuai 3 kolom tabel users port 3307 kamu braay
$query = "INSERT INTO users (username, password, role) VALUES ('$username', '$password', '$role')";
$result = mysqli_query($koneksi, $query);

if ($result) {
    // 🟢 Jika sukses masuk database laptop
    echo json_encode([
        "status" => "success",
        "message" => "Akun berhasil didaftarkan jirr! Hubungan kita sukses!"
    ]);
} else {
    // ❌ Jika gagal (misal usernamenya udah kembar/duplikat)
    echo json_encode([
        "status" => "error",
        "message" => "Gagal register cok! Username mungkin udah dipakai: " . mysqli_error($koneksi)
    ]);
}
?>