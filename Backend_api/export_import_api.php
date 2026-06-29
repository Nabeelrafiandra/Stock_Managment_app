<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
include 'koneksi.php'; // Koneksi port 3307 laptopmu jirr

// Tangkap row data JSON yang dikirim masal dari Flutter
$jsonData = file_get_contents('php://input');
$dataBarang = json_decode($jsonData, true);

if (!empty($dataBarang) && is_array($dataBarang)) {
    $sukses = 0;
    $gagal = 0;

    foreach ($dataBarang as $row) {
        $code     = isset($row['code']) ? mysqli_real_escape_string($koneksi, $row['code']) : '';
        $name     = isset($row['name']) ? mysqli_real_escape_string($koneksi, $row['name']) : '';
        $qty      = isset($row['qty']) ? (int)$row['qty'] : 0;
        $category = isset($row['category']) ? mysqli_real_escape_string($koneksi, $row['category']) : 'Umum';

        if (empty($code) || empty($name)) {
            $gagal++;
            continue;
        }

        // Jalankan query UPSERT: Kalau kode barang udah ada, update stoknya. Kalau belum ada, insert baru jirr!
        $query = "INSERT INTO items (code, name, qty, category) 
                  VALUES ('$code', '$name', $qty, '$category') 
                  ON DUPLICATE KEY UPDATE name='$name', qty=qty+$qty, category='$category'";
        
        if (mysqli_query($koneksi, $query)) {
            $sukses++;
        } else {
            $gagal++;
        }
    }

    echo json_encode([
        "status" => "Sukses",
        "message" => "$sukses barang berhasil dimasukkan, $gagal gagal cok!"
    ]);
} else {
    echo json_encode(["status" => "Gagal", "message" => "Data kosong jirr!"]);
}

mysqli_close($koneksi);
?>