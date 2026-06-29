<?php
ob_start();
include 'koneksi.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $id_barang    = isset($_POST['id_barang']) ? trim($_POST['id_barang']) : '';
    $qty_input     = isset($_POST['qty']) ? intval($_POST['qty']) : 0;
    $description   = isset($_POST['description']) ? trim($_POST['description']) : '';

    // 🟢 OTOMATIS: Membuat folder 'uploads/' di htdocs jika belum ada
    $target_dir = "uploads/";
    if (!file_exists($target_dir)) {
        mkdir($target_dir, 0777, true);
    }

    // Proses pemindahan file fisik foto dari HP ke folder laptop
    $img_path = "";
    if (isset($_FILES['image']['name']) && $_FILES['image']['error'] == 0) {
        $file_extension = pathinfo($_FILES['image']['name'], PATHINFO_EXTENSION);
        // Menamai ulang file dengan timestamp unik agar nama file tidak bentrok
        $new_file_name = "IMG_" . time() . "_" . rand(1000, 9999) . "." . $file_extension;
        $target_file = $target_dir . $new_file_name;

        if (move_uploaded_file($_FILES['image']['tmp_name'], $target_file)) {
            $img_path = $new_file_name; // Variabel yang akan dimasukkan ke kolom database img_path
        }
    }

    // Periksa status barang di katalog
    $checkQuery = "SELECT name, qty, img_path FROM items WHERE id_barang = '$id_barang'";
    $checkResult = mysqli_query($koneksi, $checkQuery);

    if (mysqli_num_rows($checkResult) > 0) {
        // BARANG SUDAH ADA (MUTASI STOK)
        $row = mysqli_fetch_assoc($checkResult);
        $barang_name = $row['name']; 
        $qty_before  = intval($row['qty']);
        $qty_after   = $qty_input; 
        $selisih_qty = abs($qty_after - $qty_before); 
        $type_log    = ($qty_after > $qty_before) ? 'BARANG MASUK' : 'BARANG KELUAR';

        if (!empty($img_path)) {
            $queryItem = "UPDATE items SET qty = '$qty_after', img_path = '$img_path', description = '$description' WHERE id_barang = '$id_barang'";
        } else {
            $queryItem = "UPDATE items SET qty = '$qty_after', description = '$description' WHERE id_barang = '$id_barang'";
        }
    } else {
        // BARANG BARU (DAFTAR PERTAMA KALI)
        $code         = isset($_POST['code']) ? trim($_POST['code']) : '';
        $barang_name  = isset($_POST['name']) ? trim($_POST['name']) : '';
        $category     = isset($_POST['category']) ? trim($_POST['category']) : 'Umum';
        $qty_before  = 0;
        $qty_after   = $qty_input;
        $selisih_qty = $qty_input; 
        $type_log    = 'BARANG BARU';

        $queryItem = "INSERT INTO items (id_barang, code, name, qty, category, img_path, description) 
                      VALUES ('$id_barang', '$code', '$barang_name', '$qty_after', '$category', '$img_path', '$description')";
    }
    
    $queryHistory = "INSERT INTO history (`item_name`, `type`, `qty`, `qty-before`, `qty-after`, `description`, `date`) 
                     VALUES ('$barang_name', '$type_log', '$selisih_qty', '$qty_before', '$qty_after', '$description', NOW())";

    ob_clean();
    if (mysqli_query($koneksi, $queryItem) && mysqli_query($koneksi, $queryHistory)) {
        echo "Sukses";
    } else {
        echo "Gagal SQL: " . mysqli_error($koneksi);
    }
}
ob_end_flush();
?>