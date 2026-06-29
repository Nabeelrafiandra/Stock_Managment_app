import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../model/stock_item.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'stock_v13.db');
    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      // 1. TABEL ITEMS
      await db.execute('''
        CREATE TABLE items(
          id_barang TEXT PRIMARY KEY, 
          code TEXT,
          name TEXT,
          qty INTEGER,
          category TEXT, 
          image_path TEXT
        )
      ''');

      // 2. TABEL HISTORY
      await db.execute('''
        CREATE TABLE history(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          item_name TEXT,
          type TEXT, 
          qty INTEGER,       
          qty_before INTEGER, 
          qty_after INTEGER,  
          date TEXT
        )
      ''');

      // 3. TABEL USERS (Untuk Login & Registrasi)
      await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE,
          password TEXT,
          role TEXT
        )
      ''');

      // Daftarkan satu akun admin default saat database pertama kali dibuat
      await db.insert('users', {
        'username': 'admin',
        'password': 'admin123',
        'role': 'admin',
      });
    });
  }

  // --- FUNGSI AUTH (LOGIN & REGISTRASI) ---
  // Fungsi Registrasi User Baru
  Future<int> registerUser(String username, String password, String role) async {
    final db = await database;
    return await db.insert('users', {
      'username': username,
      'password': password,
      'role': role,
    });
  }

  // Fungsi Cek Akun saat Login
  Future<Map<String, dynamic>?> checkLogin(String username, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> res = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (res.isNotEmpty) {
      return res.first;
    }
    return null;
  }

  // --- FUNGSI HISTORY RIWAYAT STOK ---
  Future<void> addHistory(String name, String type, int qty, int before, int after) async {
    final db = await database;
    await db.insert('history', {
      'item_name': name,
      'type': type,
      'qty': qty,
      'qty_before': before,
      'qty_after': after,
      'date': DateTime.now().toString(),
    });
  }

  Future<List<Map<String, dynamic>>> getRecentHistory() async {
    final db = await database;
    return await db.query('history', orderBy: 'id DESC', limit: 10);
  }

  // --- FUNGSI CRUD BARANG ---
  Future<List<StockItem>> getAllStock() async {
    final db = await database;
    final result = await db.query('items', orderBy: 'name ASC');
    return result.map((e) => StockItem.fromMap(e)).toList();
  }

  Future<int> insertItem(StockItem item) async {
    final db = await database;
    return db.insert('items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateItem(StockItem item) async {
    final db = await database;
    return await db.update(
        'items',
        item.toMap(),
        where: 'id_barang = ?',
        whereArgs: [item.idBarang]
    );
  }

  Future<int> deleteItem(String idBarang) async {
    final db = await database;
    return await db.delete(
        'items',
        where: 'id_barang = ?',
        whereArgs: [idBarang]
    );
  }

  // --- FUNGSI EXPORT & IMPORT CSV ---
  Future<String> exportToCSV() async {
    final db = await database;
    final List<Map<String, dynamic>> querySnapshot = await db.query('items');

    List<List<dynamic>> csvData = [
      ["ID Barang", "Kode Barcode", "Nama Barang", "Jumlah", "Kategori", "Path Gambar"],
    ];

    for (var row in querySnapshot) {
      csvData.add([
        row['id_barang'],
        row['code'],
        row['name'],
        row['qty'],
        row['category'],
        row['image_path'] ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(csvData);
  }

  Future<void> importFromExternalCSV(File file) async {
    final csvString = await file.readAsString();
    final lines = const LineSplitter().convert(csvString);
    final db = await database;
    Batch batch = db.batch();

    for (int i = 1; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue; // Lewati jika ada baris kosong

      final row = lines[i].split(',');
      if (row.length >= 4) {
        batch.insert('items', {
          'id_barang': row[0].trim(),
          'code': row[1].trim(),
          'name': row[2].trim(),
          'qty': int.tryParse(row[3].trim()) ?? 0,
          'category': row.length > 4 ? row[4].trim() : 'Umum',
          'image_path': row.length > 5 ? row[5].trim() : '',
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    await batch.commit(noResult: true);
  }
}