<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

// 🟢 Selalu panggil koneksi database port 3307 kita braay
include 'koneksi.php';

// Tangkap nomor barcode yang dikirim dari scan HP jirr
$code = isset($_GET['code']) ? $_GET['code'] : '';

if (empty($code)) {
    echo json_encode(["status" => "error", "message" => "Kode barcode kosong cok!"]);
    exit();
}

// Cari data barang berdasarkan nomor barcode-nya braay
$sql = "SELECT * FROM items WHERE code = '$code' LIMIT 1";
$result = mysqli_query($koneksi, $sql);

if ($result && mysqli_num_rows($result) > 0) {
    $row = mysqli_fetch_assoc($result);
    
    // Kirim data barang lengkap ke Flutter jirr
    echo json_encode([
        "status" => "success",
        "data" => [
            "id_barang" => $row['id_barang'],
            "code"      => $row['code'],
            "name"      => $row['name'],
            "qty"       => intval($row['qty']),
            "category"  => $row['category']
        ]
    ]);
} else {
    echo json_encode(["status" => "empty", "message" => "Barang belum terdaftar di database laptop jirr!"]);
}

mysqli_close($koneksi);
?>