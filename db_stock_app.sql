-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3307
-- Generation Time: Jun 29, 2026 at 03:38 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `db_stock_app`
--

-- --------------------------------------------------------

--
-- Table structure for table `history`
--

CREATE TABLE `history` (
  `id` int(11) NOT NULL,
  `item_name` varchar(100) NOT NULL,
  `type` varchar(20) NOT NULL,
  `qty` int(11) NOT NULL,
  `qty-before` int(11) NOT NULL,
  `qty-after` int(11) NOT NULL,
  `date` varchar(50) NOT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `history`
--

INSERT INTO `history` (`id`, `item_name`, `type`, `qty`, `qty-before`, `qty-after`, `date`, `description`) VALUES
(1, 'Laptop', 'BARANG BARU', 20, 0, 20, '2026-06-02 09:36:22', NULL),
(2, 'Laptop', 'BARANG BARU', 20, 0, 20, '2026-06-02 09:49:56', NULL),
(3, 'HP', 'BARANG BARU', 20, 0, 20, '2026-06-02 10:00:48', NULL),
(4, 'HP', 'BARANG KELUAR', 5, 10, 5, '2026-06-02 10:03:01', NULL),
(5, 'Pulpen', 'BARANG BARU', 20, 0, 20, '2026-06-02 15:04:14', NULL),
(6, 'Pulpen', 'BARANG KELUAR', 10, 20, 10, '2026-06-02 10:04:55', NULL),
(7, 'Pulpen', 'BARANG KELUAR', 5, 10, 5, '2026-06-04 09:51:22', NULL),
(8, 'Pulpen', 'BARANG MASUK', 2, 5, 7, '2026-06-04 10:40:40', NULL),
(9, 'Laptop', 'BARANG MASUK', 5, 20, 25, '2026-06-04 10:45:05', NULL),
(10, 'Jam Tangan', 'BARANG BARU', 10, 0, 10, '2026-06-04 16:11:45', NULL),
(11, 'HP', 'EDIT DATA', 15, 10, 15, '2026-06-05 15:39:07', 'Untuk staff'),
(12, 'Pulpen', 'HAPUS BARANG', 0, 7, 0, '2026-06-05 15:41:17', NULL),
(13, 'Jam Tangan', 'BARANG MASUK', 20, 15, 20, '2026-06-05 15:42:06', ''),
(14, 'Jam Tangan', 'EDIT DATA', 15, 20, 15, '2026-06-05 16:04:26', 'Untuk bagian sekretariat'),
(15, 'Laptop', 'EDIT DATA', 20, 25, 20, '2026-06-07 20:50:56', 'untuk bagian Sekretariat'),
(16, 'Jam Tangan', 'BARANG MASUK', 5, 15, 20, '2026-06-08 13:57:39', ''),
(17, 'Pulpen', 'EDIT DATA', 10, 5, 10, '2026-06-08 13:59:12', ''),
(18, 'Jam Tangan', 'BARANG KELUAR', 5, 20, 15, '2026-06-08 14:28:39', 'Untuk Keamanan'),
(19, 'Mouse', 'BARANG BARU', 10, 0, 10, '2026-06-08 15:22:04', ''),
(20, 'Mouse', 'HAPUS BARANG', 0, 10, 0, '2026-06-08 15:22:47', NULL),
(21, 'Mouse', 'BARANG BARU', 10, 0, 10, '2026-06-08 15:23:18', ''),
(22, 'Mouse', 'BARANG MASUK', 50, 10, 60, '2026-06-08 15:34:28', ''),
(23, 'Mouse', 'BARANG KELUAR', 25, 60, 35, '2026-06-08 15:35:34', 'Untuk Bidang Sekeretariat Dan Pelaporan'),
(24, 'Mouse', 'BARANG KELUAR', 1, 35, 34, '2026-06-08 20:23:29', ''),
(25, 'Mouse', 'EDIT DATA', 34, 34, 34, '2026-06-09 15:23:53', ''),
(26, 'Mouse', 'EDIT DATA', 34, 34, 34, '2026-06-09 15:48:04', ''),
(27, 'Mouse', 'EDIT DATA', 34, 34, 34, '2026-06-09 15:56:30', ''),
(28, 'Jam Tangan', 'EDIT DATA', 15, 15, 15, '2026-06-22 13:41:57', 'Masang foto'),
(29, 'Laptop', 'BARANG KELUAR', 5, 20, 15, '2026-06-24 17:35:49', 'Buat satpam'),
(30, 'kamila', 'BARANG BARU', 1, 0, 1, '2026-06-27 14:31:21', 'Barang masuk'),
(31, 'Alexa Denim', 'BARANG BARU', 1, 0, 1, '2026-06-27 14:33:13', 'Masuk'),
(32, 'Alexa Denim', 'BARANG KELUAR', 1, 1, 0, '2026-06-27 14:35:29', ''),
(33, 'Alexa Denim', 'BARANG MASUK', 5, 0, 5, '2026-06-27 16:46:42', 'Masuk'),
(34, 'baju', 'BARANG BARU', 5, 0, 5, '2026-06-27 16:47:56', 'Masuk'),
(35, 'baju', 'EDIT DATA', 5, 5, 5, '2026-06-27 16:48:24', ''),
(36, 'Kertas HVS A4 80gr Sinar Dunia', 'BARANG BARU (CSV)', 15, 0, 15, '2026-06-27 17:15:10', 'Import masal via file CSV'),
(37, 'Mouse Wireless Logi M170', 'BARANG BARU (CSV)', 8, 0, 8, '2026-06-27 17:15:10', 'Import masal via file CSV'),
(38, 'Map Dokumen Perbup Transparan', 'BARANG BARU (CSV)', 50, 0, 50, '2026-06-27 17:15:10', 'Import masal via file CSV'),
(39, 'Pulpen Snowman V-1 Hitam', 'BARANG BARU (CSV)', 120, 0, 120, '2026-06-27 17:15:10', 'Import masal via file CSV'),
(40, 'Kabel HDMI TO VGA 1.5m', 'BARANG BARU (CSV)', 6, 0, 6, '2026-06-27 17:15:10', 'Import masal via file CSV'),
(41, 'Buku Log Laporan Pertanggungjawaban', 'BARANG BARU (CSV)', 35, 0, 35, '2026-06-27 17:15:10', 'Import masal via file CSV'),
(42, 'Mouse', 'BARANG BARU', 5, 0, 5, '2026-06-29 08:08:33', 'Masuk'),
(43, 'webcam', 'BARANG BARU', 5, 0, 5, '2026-06-29 08:09:33', 'Masuk');

-- --------------------------------------------------------

--
-- Table structure for table `items`
--

CREATE TABLE `items` (
  `id_barang` varchar(50) NOT NULL,
  `code` varchar(100) NOT NULL,
  `name` varchar(100) NOT NULL,
  `qty` int(11) NOT NULL,
  `category` varchar(100) NOT NULL,
  `img_path` varchar(255) NOT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `items`
--

INSERT INTO `items` (`id_barang`, `code`, `name`, `qty`, `category`, `img_path`, `description`) VALUES
('001', '501', 'kamila', 1, 'NAVY SPARY', '', 'Barang masuk'),
('002', '1244-A', 'Alexa Denim', 5, 'HITAM', '', 'Masuk'),
('003', 'STK-288111', 'Mouse', 5, 'ALAT ELEKTRONIK', '', 'Masuk'),
('004', 'STK-348563', 'webcam', 5, 'ALAT ELEKTRONIK', '', 'Masuk'),
('005', 'STK-650295', 'baju', 5, 'LAINNYA', '', ''),
('ART-178255531013', 'DOK-PERB-2026', 'Map Dokumen Perbup Transparan', 50, 'DOKUMEN', '', 'Import masal via file CSV'),
('ART-178255531014', '8991930000000.0', 'Pulpen Snowman V-1 Hitam', 120, 'ATK', '', 'Import masal via file CSV'),
('ART-178255531035', 'ELK-LOG-02', 'Mouse Wireless Logi M170', 8, 'ALAT ELEKTRONIK', '', 'Import masal via file CSV'),
('ART-178255531042', 'ELK-KBL-05', 'Kabel HDMI TO VGA 1.5m', 6, 'ALAT ELEKTRONIK', '', 'Import masal via file CSV'),
('ART-178255531072', '8992000000000.0', 'Kertas HVS A4 80gr Sinar Dunia', 15, 'ATK', '', 'Import masal via file CSV'),
('ART-178255531089', 'DOK-LPJ-2026', 'Buku Log Laporan Pertanggungjawaban', 35, 'DOKUMEN', '', 'Import masal via file CSV');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `username` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`username`, `password`, `role`) VALUES
('admin', '123', 'admin'),
('nabeel', '123', 'admin'),
('nara', 'nara1', 'viewer'),
('viewer', '123', 'viewer');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `history`
--
ALTER TABLE `history`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `items`
--
ALTER TABLE `items`
  ADD PRIMARY KEY (`id_barang`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`username`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `history`
--
ALTER TABLE `history`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=44;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
