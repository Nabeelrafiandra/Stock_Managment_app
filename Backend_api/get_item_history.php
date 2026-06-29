<?php
header('Content-Type: application/json');
include 'koneksi.php';

// Menangkap parameter id_barang yang dikirim dari aplikasi Flutter
$id_barang = isset($_GET['id_barang']) ? trim($_GET['id_barang']) : '';

if (empty($id_barang)) {
    echo json_encode([]);
    exit();
}

// Mengamankan string parameter untuk mencegah SQL Injection
$id_barang_safe = mysqli_real_escape_string($koneksi, $id_barang);

/**
 * LOGIKA REVISI QUERY:
 * 1. Menghubungkan tabel 'history' dan 'items' berdasarkan kesamaan nama produk.
 * 2. Menyaring data (WHERE) berdasarkan 'id_barang' spesifik yang dikirim oleh Flutter.
 * 3. Menggunakan karakter backtick (`) pada kolom bertanda hubung/minus (-) agar tidak error.
 */
$query = "SELECT h.`type`, h.`qty`, h.`qty-before`, h.`qty-after`, h.`description`, h.`date`
          FROM history h
          INNER JOIN items i ON h.`item_name` = i.`name`
          WHERE i.`id_barang` = '$id_barang_safe'
          ORDER BY h.`date` DESC";

$result = mysqli_query($koneksi, $query);

$response = array();

if ($result) {
    while($row = mysqli_fetch_assoc($result)) {
        // Menyelaraskan key JSON agar menggunakan format underscore (_) sesuai penampung di ItemHistoryPage
        $response[] = [
            "type" => $row['type'],
            "qty" => intval($row['qty']),
            "qty_before" => intval($row['qty-before']),
            "qty_after" => intval($row['qty-after']),
            "description" => $row['description'],
            "date" => $row['date']
        ];
    }
}

// Mengembalikan data dalam bentuk JSON array clean ke Flutter
echo json_encode($response);
?>