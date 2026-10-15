import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database_helper.dart';

final transactionProvider = Provider((ref) => TransactionService());

class TransactionService {
  Future<void> saveTransaction({
    required String teksAsli,
    required double nominal,
    required int selectedDebitId,
    required int selectedCreditId,
    required String extractedKeyword,
  }) async {
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      // 1. Insert into transaksi
      final String tanggal = DateTime.now().toIso8601String().substring(0, 10);

      final int transaksiId = await txn.insert('transaksi', {
        'tanggal': tanggal,
        'teks_asli': teksAsli,
        'nominal': nominal,
      });

      // 2. Insert debit row into jurnal_detail
      await txn.insert('jurnal_detail', {
        'transaksi_id': transaksiId,
        'akun_id': selectedDebitId,
        'debit': nominal,
        'kredit': 0.0,
      });

      // 3. Insert credit row into jurnal_detail
      await txn.insert('jurnal_detail', {
        'transaksi_id': transaksiId,
        'akun_id': selectedCreditId,
        'debit': 0.0,
        'kredit': nominal,
      });

      // 4. Update user_knowledge_cache
      if (extractedKeyword.isNotEmpty) {
        await txn.rawInsert('''
          INSERT INTO user_knowledge_cache (kata_kunci, akun_id, frekuensi, terakhir_dipakai)
          VALUES (?, ?, 1, ?)
          ON CONFLICT(kata_kunci) DO UPDATE SET
            akun_id = excluded.akun_id,
            frekuensi = frekuensi + 1,
            terakhir_dipakai = excluded.terakhir_dipakai
        ''', [extractedKeyword, selectedDebitId, tanggal]);
      }
    });
  }
}
