<?php
include 'koneksi.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $code        = $_POST['code'];
    $name        = $_POST['name'];
    $qty_input   = intval($_POST['qty_input']);
    $action_type = $_POST['action_type']; 

    // Ambil data stok saat ini
    $res = mysqli_query($koneksi, "SELECT qty FROM items WHERE code = '$code' LIMIT 1");
    $item = mysqli_fetch_assoc($res);
    $qty_before = intval($item['qty']);

    if ($action_type == "MASUK") {
        $qty_after = $qty_before + $qty_input;
    } else {
        $qty_after = $qty_before - $qty_input;
        if ($qty_after < 0) {
            echo json_encode(["status" => "error", "message" => "Stok di database laptop tidak cukup!"]);
            exit();
        }
    }

    // Update tabel utama items
    mysqli_query($koneksi, "UPDATE items SET qty = '$qty_after' WHERE code = '$code'");

    // FIX AKURAT: Query history disesuaikan dengan struktur tabel history kamu braay!
    mysqli_query($koneksi, "INSERT INTO history (`item_name`, `type`, `qty`, `qty-before`, `qty-after`, `date`) 
                            VALUES ('$name', '$action_type', '$qty_input', '$qty_before', '$qty_after', NOW())");

    echo json_encode(["status" => "success"]);
}
?>