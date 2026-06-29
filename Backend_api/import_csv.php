<?php
header('Content-Type: application/json');
include 'koneksi.php';

// Membaca data JSON yang dikirim oleh Flutter
$input = file_get_contents('php://input');
$data = json_decode($input, true);

if (empty($data)) {
    echo json_encode([
        "status" => "Gagal",
        "message" => "Tidak ada data CSV yang terbaca oleh server."
    ]);
    exit();
}

$suksesCount = 0;
$gagalCount = 0;

foreach ($data as $row) {
    $code     = isset($row['code']) ? trim($row['code']) : '';
    $name     = isset($row['name']) ? trim($row['name']) : '';
    $qty      = isset($row['qty']) ? intval($row['qty']) : 0;
    $category = isset($row['category']) ? trim($row['category']) : 'Umum';
    $desc     = "Import masal via file CSV";

    if (empty($code) || empty($name)) {
        $gagalCount++;
        continue;
    }

    // 🟢 OTOMATISASI ID BARANG: Membuat ID unik berbasis timestamp untuk katalog pakaian
    $id_barang = "ART-" . time() . rand(10, 99);

    // Cek apakah kode barcode tersebut sudah terdaftar di database pakaian
    $check = mysqli_query($koneksi, "SELECT id_barang FROM items WHERE code = '$code'");
    
    if (mysqli_num_rows($check) > 0) {
        // Jika barcode sudah ada, update jumlah stoknya
        $query = "UPDATE items SET qty = qty + $qty WHERE code = '$code'";
    } else {
        // Jika produk benar-benar baru, masukkan data katalog baru
        $query = "INSERT INTO items (id_barang, code, name, qty, category, description) 
                  VALUES ('$id_barang', '$code', '$name', '$qty', '$category', '$desc')";
    }

    if (mysqli_query($koneksi, $query)) {
        // Tulis juga log transaksi masuk ke tabel history toko pakaian
        $queryHistory = "INSERT INTO history (`item_name`, `type`, `qty`, `qty-before`, `qty-after`, `description`, `date`) 
                         VALUES ('$name', 'BARANG BARU (CSV)', '$qty', 0, $qty, '$desc', NOW())";
        mysqli_query($koneksi, $queryHistory);
        $suksesCount++;
    } else {
        $gagalCount++;
    }
    
    // Beri jeda sedikit agar generator timestamp id_barang tidak kembar
    usleep(10000); 
}

echo json_encode([
    "status" => "Sukses",
    "message" => "Berhasil mengimport $suksesCount produk. Gagal: $gagalCount."
]);
?>