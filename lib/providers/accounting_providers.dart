import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database_helper.dart';
import '../data/models.dart';

// Provider for general accounts
final accountsProvider = FutureProvider<List<Akun>>((ref) async {
  final db = await DatabaseHelper.instance.database;
  final maps = await db.query('akun');
  return maps.map((map) => Akun.fromMap(map)).toList();
});

// Provider for general journal
final generalJournalProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = await DatabaseHelper.instance.database;
  return await db.rawQuery('''
    SELECT
      t.id as transaksi_id, t.tanggal, t.teks_asli,
      a.kode_akun, a.nama_akun, jd.debit, jd.kredit
    FROM transaksi t
    JOIN jurnal_detail jd ON t.id = jd.transaksi_id
    JOIN akun a ON jd.akun_id = a.id
    ORDER BY t.id ASC, jd.debit DESC
  ''');
});

// Provider for trial balance
final trialBalanceProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = await DatabaseHelper.instance.database;
  return await db.rawQuery('''
    SELECT
      a.kode_akun,
      a.nama_akun,
      SUM(jd.debit) as total_debit,
      SUM(jd.kredit) as total_kredit,
      a.posisi_normal
    FROM akun a
    LEFT JOIN jurnal_detail jd ON a.id = jd.akun_id
    GROUP BY a.id
    HAVING total_debit > 0 OR total_kredit > 0
    ORDER BY a.kode_akun ASC
  ''');
});

// Provider for ledger specific to an account
final ledgerProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, akunId) async {
  final db = await DatabaseHelper.instance.database;
  return await db.rawQuery('''
    SELECT
      t.tanggal, t.teks_asli, jd.debit, jd.kredit
    FROM transaksi t
    JOIN jurnal_detail jd ON t.id = jd.transaksi_id
    WHERE jd.akun_id = ?
    ORDER BY t.id ASC
  ''', [akunId]);
});

// Provider for user knowledge cache
final knowledgeCacheProvider = FutureProvider<List<UserKnowledgeCache>>((ref) async {
  final db = await DatabaseHelper.instance.database;
  final maps = await db.query('user_knowledge_cache');
  return maps.map((map) => UserKnowledgeCache.fromMap(map)).toList();
});
