<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

// 🟢 Panggil koneksi database port 3307 jirr
include 'koneksi.php';

// Ambil 10 riwayat aktivitas terbaru, diurutkan dari yang paling gres (id paling besar)
$sql = "SELECT * FROM history ORDER BY id DESC LIMIT 10";
$result = mysqli_query($koneksi, $sql);

$history_list = array();

if ($result) {
    while ($row = mysqli_fetch_assoc($result)) {
        // Bungkus data ke dalam array sesuai format variabel di phpMyAdmin kamu braay
        $history_list[] = array(
            "id"          => intval($row['id']),
            "item_name"   => $row['item_name'],
            "type"        => $row['type'],
            "qty"         => intval($row['qty']),
            "qty-before"  => intval($row['qty-before']), // Pas sesuai kolom pakai strip cok!
            "qty-after"   => intval($row['qty-after']),  // Pas sesuai kolom pakai strip cok!
            "date"        => $row['date']
        );
    }
    // Kirim data format JSON jirr
    echo json_encode($history_list);
} else {
    // Kalau eror kirim array kosong biar Flutter gak crash braay
    echo json_encode(array());
}

mysqli_close($koneksi);
?>