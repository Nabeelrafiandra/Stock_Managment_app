<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include 'koneksi.php';

if (isset($_GET['code'])) {
    $code = $_GET['code'];

    // Cari barang berdasarkan code barcode di tabel items
    $query = "SELECT * FROM items WHERE code = '$code' LIMIT 1";
    $result = mysqli_query($koneksi, $query);

    if ($result && mysqli_num_rows($result) > 0) {
        // 🟢 FIX UTAMA: Diganti jadi $result jirr, bukan $assoc ghaib!
        $row = mysqli_fetch_assoc($result); 
        
        // Balas ke Flutter dalam bentuk JSON jirr
        echo json_encode([
            "status" => "exists",
            "id_barang" => $row['id_barang'],
            "code" => $row['code'],
            "name" => $row['name'],
            "category" => $row['category'],
            "qty" => intval($row['qty'])
        ]);
    } else {
        // 🟢 FIX: Samakan status response-nya dengan kodingan input_page.dart kamu (pakai 'new' atau 'not_found')
        echo json_encode([
            "status" => "new",
            "message" => "Barang baru terdeteksi jirr"
        ]);
    }
} else {
    echo json_encode([
        "status" => "error",
        "message" => "Parameter code tidak ditemukan cok!"
    ]);
}
?>