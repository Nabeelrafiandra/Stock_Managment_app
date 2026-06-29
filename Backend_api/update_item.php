<?php
include 'koneksi.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // Menangkap parameter mutasi atau perubahan data dari aplikasi
    $id_barang    = $_POST['id_barang'];
    $name         = $_POST['name'];
    $category     = $_POST['category'];
    $qty          = $_POST['qty'];
    $type_history = $_POST['type_history'];
    $qty_before   = $_POST['qty_before'];
    $qty_after    = $_POST['qty_after'];

    // Menangkap variabel catatan deskripsi pembaruan data
    $description  = isset($_POST['description']) ? $_POST['description'] : '';

    // 1. Memperbarui data pada tabel utama (items)
    $queryUpdate = "UPDATE items SET 
                    name = '$name', 
                    category = '$category', 
                    qty = '$qty', 
                    description = '$description' 
                    WHERE id_barang = '$id_barang'";
    mysqli_query($koneksi, $queryUpdate);

    // 2. Memperbarui Log Riwayat ke Tabel History
    // Kolom disesuaikan dari 'id_barang' menjadi 'item_name' agar sesuai struktur tabel history Anda
    $queryHistory = "INSERT INTO history (`item_name`, `type`, `qty`, `qty-before`, `qty-after`, `description`, `date`) 
                     VALUES ('$name', '$type_history', '$qty', '$qty_before', '$qty_after', '$description', NOW())";

    if (mysqli_query($koneksi, $queryHistory)) {
        echo "Sukses";
    } else {
        echo "Gagal SQL: " . mysqli_error($koneksi);
    }
}
?>