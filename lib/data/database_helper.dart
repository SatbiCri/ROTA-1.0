import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('rota_accounting.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE akun (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kode_akun TEXT UNIQUE NOT NULL,
        nama_akun TEXT NOT NULL,
        kategori TEXT NOT NULL CHECK(kategori IN ('ASET', 'LIABILITAS', 'EKUITAS', 'PENDAPATAN', 'BEBAN')),
        posisi_normal TEXT NOT NULL CHECK(posisi_normal IN ('DEBIT', 'KREDIT'))
      )
    ''');

    await db.execute('''
      CREATE TABLE transaksi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tanggal TEXT NOT NULL,
        teks_asli TEXT NOT NULL,
        nominal REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE jurnal_detail (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaksi_id INTEGER NOT NULL,
        akun_id INTEGER NOT NULL,
        debit REAL DEFAULT 0,
        kredit REAL DEFAULT 0,
        FOREIGN KEY (transaksi_id) REFERENCES transaksi (id) ON DELETE CASCADE,
        FOREIGN KEY (akun_id) REFERENCES akun (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE user_knowledge_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kata_kunci TEXT UNIQUE NOT NULL,
        akun_id INTEGER NOT NULL,
        frekuensi INTEGER DEFAULT 1,
        terakhir_dipakai TEXT NOT NULL,
        FOREIGN KEY (akun_id) REFERENCES akun (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE akun_embedding (
        akun_id INTEGER PRIMARY KEY,
        vector_json TEXT NOT NULL,
        FOREIGN KEY (akun_id) REFERENCES akun (id)
      )
    ''');

    await _seedDatabase(db);
  }

  Future<void> _seedDatabase(Database db) async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/semantic_seed.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> accountsData = jsonData['accounts'];

      for (var accountMap in accountsData) {
        final akunId = await db.insert('akun', {
          'id': accountMap['id'],
          'kode_akun': accountMap['kode_akun'],
          'nama_akun': accountMap['nama_akun'],
          'kategori': accountMap['kategori'],
          'posisi_normal': accountMap['posisi_normal'],
        });

        await db.insert('akun_embedding', {
          'akun_id': akunId,
          'vector_json': json.encode(accountMap['vector_json']),
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error seeding database: \$e');
    }
  }
}
