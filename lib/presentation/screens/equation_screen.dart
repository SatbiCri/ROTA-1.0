import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/colors.dart';
import '../../providers/accounting_providers.dart';

class EquationScreen extends ConsumerWidget {
  const EquationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final generalJournalAsyncValue = ref.watch(generalJournalProvider);
    final accountsAsyncValue = ref.watch(accountsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: AppBar(
        title: const Text('Persamaan Dasar', style: TextStyle(color: AppColors.primaryText)),
        backgroundColor: AppColors.cardSurface,
      ),
      body: accountsAsyncValue.when(
        data: (accounts) {
          final assetAccounts = accounts.where((a) => a.kategori == 'ASET').toList();
          final liabilityAccounts = accounts.where((a) => a.kategori == 'LIABILITAS').toList();
          final equityAccounts = accounts.where((a) => ['EKUITAS', 'PENDAPATAN', 'BEBAN'].contains(a.kategori)).toList();

          return generalJournalAsyncValue.when(
            data: (journal) {
              // Group journal entries by transaction_id
              final Map<int, Map<String, dynamic>> transactions = {};
              for (var entry in journal) {
                final id = entry['transaksi_id'];
                if (!transactions.containsKey(id)) {
                  transactions[id] = {
                    'tanggal': entry['tanggal'],
                    'keterangan': entry['teks_asli'],
                    'mutasi': <String, double>{},
                  };
                }

                final String kodeAkun = entry['kode_akun'];
                final double debit = (entry['debit'] as num).toDouble();
                final double kredit = (entry['kredit'] as num).toDouble();

                final account = accounts.firstWhere((a) => a.kodeAkun == kodeAkun);
                double mutasi = 0;

                if (account.kategori == 'BEBAN' || account.kategori == 'PRIVE') {
                   // Expenses and Prive decrease Equity
                   mutasi = (account.posisiNormal == 'DEBIT') ? (kredit - debit) : (debit - kredit);
                } else {
                   mutasi = (account.posisiNormal == 'DEBIT') ? (debit - kredit) : (kredit - debit);
                }

                transactions[id]!['mutasi'][kodeAkun] = ((transactions[id]!['mutasi'][kodeAkun] as double?) ?? 0.0) + mutasi;
              }

              // Calculate total balances
              double totalAsset = 0;
              double totalLiability = 0;
              double totalEquity = 0;

              Map<String, double> colTotals = {};

              for (var txn in transactions.values) {
                final mutasiMap = txn['mutasi'] as Map<String, double>;
                mutasiMap.forEach((kode, val) {
                  colTotals[kode] = (colTotals[kode] ?? 0.0) + val;
                  final account = accounts.firstWhere((a) => a.kodeAkun == kode);
                  if (account.kategori == 'ASET') {
                    totalAsset += val;
                  } else if (account.kategori == 'LIABILITAS') {
                    totalLiability += val;
                  } else {
                    totalEquity += val;
                  }
                });
              }

              bool isBalanced = (totalAsset - (totalLiability + totalEquity)).abs() < 0.01;

              final formatter = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.cardSurface,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Aset = Liabilitas + Ekuitas', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isBalanced ? AppColors.neonMint.withOpacity(0.2) : AppColors.laserCoral.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            isBalanced ? 'SEIMBANG' : 'SELISIH',
                            style: TextStyle(
                              color: isBalanced ? AppColors.neonMint : AppColors.laserCoral,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppColors.cardSurface),
                          dataRowColor: WidgetStateProperty.all(AppColors.canvasBackground),
                          dividerThickness: 1,
                          border: TableBorder.all(color: AppColors.borderLine),
                          columns: [
                            const DataColumn(label: Text('Tgl', style: TextStyle(color: AppColors.primaryText))),
                            const DataColumn(label: Text('Ket', style: TextStyle(color: AppColors.primaryText))),
                            ...assetAccounts.map((a) => DataColumn(label: Text(a.namaAkun, style: const TextStyle(color: AppColors.neonMint)))),
                            const DataColumn(label: Text('=', style: TextStyle(color: AppColors.primaryText))),
                            ...liabilityAccounts.map((a) => DataColumn(label: Text(a.namaAkun, style: const TextStyle(color: AppColors.laserCoral)))),
                            const DataColumn(label: Text('+', style: TextStyle(color: AppColors.primaryText))),
                            ...equityAccounts.map((a) => DataColumn(label: Text(a.namaAkun, style: const TextStyle(color: AppColors.electricCyan)))),
                          ],
                          rows: [
                            ...transactions.values.map((txn) {
                              final mutasi = txn['mutasi'] as Map<String, double>;
                              return DataRow(
                                cells: [
                                  DataCell(Text(txn['tanggal'].toString().substring(5, 10), style: const TextStyle(color: AppColors.secondaryText))),
                                  DataCell(Text(txn['keterangan'].toString(), style: const TextStyle(color: AppColors.primaryText))),
                                  ...assetAccounts.map((a) => _buildDataCell(mutasi[a.kodeAkun] ?? 0.0, formatter)),
                                  const DataCell(Text('=')),
                                  ...liabilityAccounts.map((a) => _buildDataCell(mutasi[a.kodeAkun] ?? 0.0, formatter)),
                                  const DataCell(Text('+')),
                                  ...equityAccounts.map((a) => _buildDataCell(mutasi[a.kodeAkun] ?? 0.0, formatter)),
                                ],
                              );
                            }),
                            DataRow(
                              color: WidgetStateProperty.all(AppColors.cardSurface),
                              cells: [
                                const DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText))),
                                const DataCell(Text('')),
                                ...assetAccounts.map((a) => _buildDataCell(colTotals[a.kodeAkun] ?? 0.0, formatter, isTotal: true)),
                                const DataCell(Text('')),
                                ...liabilityAccounts.map((a) => _buildDataCell(colTotals[a.kodeAkun] ?? 0.0, formatter, isTotal: true)),
                                const DataCell(Text('')),
                                ...equityAccounts.map((a) => _buildDataCell(colTotals[a.kodeAkun] ?? 0.0, formatter, isTotal: true)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.electricCyan)),
            error: (err, stack) => const Center(child: Text('Error: \$err', style: TextStyle(color: AppColors.laserCoral))),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.electricCyan)),
        error: (err, stack) => const Center(child: Text('Error: \$err', style: TextStyle(color: AppColors.laserCoral))),
      ),
    );
  }

  DataCell _buildDataCell(double amount, NumberFormat formatter, {bool isTotal = false}) {
    if (amount == 0 && !isTotal) return const DataCell(Text(''));
    return DataCell(
      Container(
        alignment: Alignment.centerRight,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            formatter.format(amount),
            textAlign: TextAlign.right,
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}
