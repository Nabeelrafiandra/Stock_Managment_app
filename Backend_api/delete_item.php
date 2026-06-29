<?php
include 'koneksi.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $id_barang = $_POST['id_barang'];

    // 1. Ambil nama barang dulu untuk keperluan log history jirr
    $res = mysqli_query($koneksi, "SELECT name, qty FROM items WHERE id_barang = '$id_barang' LIMIT 1");
    if(mysqli_num_rows($res) > 0) {
        $item = mysqli_fetch_assoc($res);
        $name = $item['name'];
        $qty_before = intval($item['qty']);

        // 2. Hapus barang dari tabel utama
        $queryDelete = "DELETE FROM items WHERE id_barang = '$id_barang'";
        
        // 3. Catat riwayat penghapusan ke tabel history (sesuai nama kolom terbarumu braay!)
        $queryHistory = "INSERT INTO history (`item_name`, `type`, `qty`, `qty-before`, `qty-after`, `date`) 
                         VALUES ('$name', 'HAPUS BARANG', 0, '$qty_before', 0, NOW())";

        if (mysqli_query($koneksi, $queryDelete) && mysqli_query($koneksi, $queryHistory)) {
            echo "Sukses";
        } else {
            echo "Gagal SQL: " . mysqli_error($koneksi);
        }
    } else {
        echo "Barang tidak ditemukan di server";
    }
}
?>