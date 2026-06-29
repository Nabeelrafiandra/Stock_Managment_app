<?php
$host = "localhost:3307";
$user = "root";
$pass = "";
// Sesuaikan dengan nama database di phpMyAdmin kamu cok (di screenshot namanya db_stock_app)
$db   = "db_stock_app"; 

$koneksi = mysqli_connect($host, $user, $pass, $db);

if (!$koneksi) {
    die("Koneksi database Gagal jirr: " . mysqli_connect_error());
}
?>