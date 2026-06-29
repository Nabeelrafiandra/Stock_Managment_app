<?php
include 'koneksi.php';

$name = $_GET['name'];
$query = "SELECT code FROM items WHERE LOWER(name) = LOWER('$name') ORDER BY id_barang ASC LIMIT 1";
$result = mysqli_query($koneksi, $query);

if (mysqli_num_rows($result) > 0) {
    $row = mysqli_fetch_assoc($result);
    echo json_encode(["status" => "success", "code" => $row['code']]);
} else {
    echo json_encode(["status" => "not_found"]);
}
?>