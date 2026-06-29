<?php
// 1. Atur header di paling atas biar browser & Flutter tahu ini format JSON jirr
header('Content-Type: application/json; charset=utf-8');

// 2. Panggil file koneksi database kamu
include 'koneksi.php';

// 3. Ambil semua data barang dari tabel items laptop
$query = "SELECT * FROM items ORDER BY id_barang DESC";
$result = mysqli_query($koneksi, $query);

$items = [];

if ($result) {
    // 🟢 Ambil data satu per satu dari database laptop braay
    while ($row = mysqli_fetch_assoc($result)) {
        $items[] = [
            "id_barang" => $row['id_barang'],
            "code"      => $row['code'],
            "name"      => $row['name'],
            "qty"       => intval($row['qty']),
            "category"  => $row['category'],
            "imagePath" => $row['img_path']
        ];
    }
    
    // Kirim balik hasilnya berbentuk JSON Array braay
    echo json_encode($items);

} else {
    // ❌ Kalau query-nya gagal (misal tabel items gak ada), dia bakal teriak di sini cok!
    echo json_encode([
        "status" => "error",
        "message" => "Gagal eksekusi tabel items jirr: " . mysqli_error($koneksi)
    ]);
}
?>