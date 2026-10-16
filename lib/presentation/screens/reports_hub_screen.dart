import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/colors.dart';
import '../../providers/accounting_providers.dart';
import '../../data/database_helper.dart';

class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.canvasBackground,
        appBar: AppBar(
          title: const Text('Reports Hub', style: TextStyle(color: AppColors.primaryText)),
          backgroundColor: AppColors.cardSurface,
          bottom: const TabBar(
            labelColor: AppColors.electricCyan,
            unselectedLabelColor: AppColors.secondaryText,
            indicatorColor: AppColors.electricCyan,
            tabs: [
              Tab(text: 'Laporan Keuangan'),
              Tab(text: 'Pusat Memori'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _FinancialReportsView(),
            _MemoryCenterView(),
          ],
        ),
      ),
    );
  }
}

class _FinancialReportsView extends ConsumerWidget {
  const _FinancialReportsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trialBalanceAsync = ref.watch(trialBalanceProvider);
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return trialBalanceAsync.when(
      data: (balances) {
        if (balances.isEmpty) return const Center(child: Text('Belum ada transaksi', style: TextStyle(color: AppColors.secondaryText)));

        double totalPendapatan = 0;
        double totalBeban = 0;
        double totalAset = 0;
        double totalLiabilitas = 0;
        double totalEkuitas = 0;

        for (var b in balances) {
          final String kode = b['kode_akun'];
          final String posNormal = b['posisi_normal'];
          final double tDebit = (b['total_debit'] as num).toDouble();
          final double tKredit = (b['total_kredit'] as num).toDouble();

          double saldo = posNormal == 'DEBIT' ? (tDebit - tKredit) : (tKredit - tDebit);

          if (kode.startsWith('1')) {
            totalAset += saldo;
          } else if (kode.startsWith('2')) {
            totalLiabilitas += saldo;
          } else if (kode.startsWith('3')) {
            totalEkuitas += saldo;
          } else if (kode.startsWith('4')) {
            totalPendapatan += saldo;
          } else if (kode.startsWith('5')) {
            totalBeban += saldo;
          }
        }

        final double labaRugi = totalPendapatan - totalBeban;
        final double ekuitasAkhir = totalEkuitas + labaRugi;
        final bool isBalanced = (totalAset - (totalLiabilitas + ekuitasAkhir)).abs() < 0.01;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildReportCard(
                title: 'Laporan Laba Rugi',
                items: [
                  _ReportItem('Total Pendapatan', totalPendapatan, isPositive: true),
                  _ReportItem('Total Beban', totalBeban, isPositive: false),
                  _ReportItem('Laba Bersih', labaRugi, isBold: true, isPositive: labaRugi >= 0),
                ],
                formatter: formatter,
              ),
              const SizedBox(height: 16),
              _buildReportCard(
                title: 'Laporan Posisi Keuangan (Neraca)',
                items: [
                  _ReportItem('Total Aset', totalAset, isPositive: true),
                  _ReportItem('Total Liabilitas', totalLiabilitas, isPositive: false),
                  _ReportItem('Ekuitas Awal', totalEkuitas, isPositive: true),
                  _ReportItem('Laba Ditahan', labaRugi, isPositive: labaRugi >= 0),
                  _ReportItem('Total Liabilitas & Ekuitas', totalLiabilitas + ekuitasAkhir, isBold: true, isPositive: true),
                ],
                formatter: formatter,
                footerText: isBalanced ? 'STATUS: SEIMBANG' : 'STATUS: SELISIH',
                isBalanced: isBalanced,
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.electricCyan)),
      error: (e, s) => const Center(child: Text('Error: \$e', style: TextStyle(color: AppColors.laserCoral))),
    );
  }

  Widget _buildReportCard({
    required String title,
    required List<_ReportItem> items,
    required NumberFormat formatter,
    String? footerText,
    bool isBalanced = true,
  }) {
    return Card(
      color: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.borderLine),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(color: AppColors.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(color: AppColors.borderLine),
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        color: item.isBold ? AppColors.primaryText : AppColors.secondaryText,
                        fontWeight: item.isBold ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatter.format(item.amount),
                        style: TextStyle(
                          color: item.isBold
                              ? (item.isPositive ? AppColors.neonMint : AppColors.laserCoral)
                              : AppColors.primaryText,
                          fontWeight: item.isBold ? FontWeight.bold : FontWeight.normal,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (footerText != null) ...[
              const Divider(color: AppColors.borderLine),
              Text(
                footerText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isBalanced ? AppColors.neonMint : AppColors.laserCoral,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportItem {
  final String label;
  final double amount;
  final bool isBold;
  final bool isPositive;

  _ReportItem(this.label, this.amount, {this.isBold = false, this.isPositive = true});
}

class _MemoryCenterView extends ConsumerWidget {
  const _MemoryCenterView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoryAsync = ref.watch(knowledgeCacheProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return memoryAsync.when(
      data: (memoryList) {
        if (memoryList.isEmpty) return const Center(child: Text('Belum ada memori cache', style: TextStyle(color: AppColors.secondaryText)));

        return accountsAsync.when(
          data: (accounts) {
            return ListView.builder(
              itemCount: memoryList.length,
              itemBuilder: (context, index) {
                final mem = memoryList[index];
                final akunName = accounts.firstWhere((a) => a.id == mem.akunId, orElse: () => accounts.first).namaAkun;

                return Card(
                  color: AppColors.cardSurface,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(mem.kataKunci, style: const TextStyle(color: AppColors.electricCyan, fontWeight: FontWeight.bold)),
                    subtitle: Text('Akun: $akunName', style: const TextStyle(color: AppColors.secondaryText)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Chip(
                          label: const Text('Freq: \${mem.frekuensi}'),
                          backgroundColor: AppColors.cyberViolet.withOpacity(0.2),
                          labelStyle: const TextStyle(color: AppColors.cyberViolet),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppColors.electricCyan),
                          onPressed: () {
                            _showEditDialog(context, ref, mem.id!, mem.kataKunci, mem.akunId, accounts);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.laserCoral),
                          onPressed: () async {
                            final db = await DatabaseHelper.instance.database;
                            await db.delete('user_knowledge_cache', where: 'id = ?', whereArgs: [mem.id]);
                            ref.invalidate(knowledgeCacheProvider);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.electricCyan)),
          error: (e, s) => const Center(child: Text('Error: \$e', style: TextStyle(color: AppColors.laserCoral))),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.electricCyan)),
      error: (e, s) => const Center(child: Text('Error: \$e', style: TextStyle(color: AppColors.laserCoral))),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, int id, String kataKunci, int currentAkunId, List accounts) {
    int selectedAkunId = currentAkunId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.cardSurface,
              title: const Text('Sunting Memori', style: TextStyle(color: AppColors.primaryText)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Kata Kunci: \$kataKunci', style: TextStyle(color: AppColors.secondaryText)),
                  const SizedBox(height: 16),
                  const Text('Pilih Akun Baru:', style: TextStyle(color: AppColors.primaryText)),
                  DropdownButton<int>(
                    value: selectedAkunId,
                    isExpanded: true,
                    dropdownColor: AppColors.cardSurface,
                    style: const TextStyle(color: AppColors.primaryText),
                    items: accounts.map((akun) {
                      return DropdownMenuItem<int>(
                        value: akun.id,
                        child: Text(akun.namaAkun, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedAkunId = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: AppColors.secondaryText)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.electricCyan),
                  onPressed: () async {
                    final db = await DatabaseHelper.instance.database;
                    await db.update('user_knowledge_cache', {'akun_id': selectedAkunId}, where: 'id = ?', whereArgs: [id]);
                    ref.invalidate(knowledgeCacheProvider);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: const Text('Simpan', style: TextStyle(color: AppColors.canvasBackground, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }
}
