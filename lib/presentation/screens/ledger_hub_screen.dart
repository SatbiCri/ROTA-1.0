import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/colors.dart';
import '../../data/models.dart';
import '../../providers/accounting_providers.dart';

class LedgerHubScreen extends StatelessWidget {
  const LedgerHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.canvasBackground,
        appBar: AppBar(
          title: const Text('Ledger Hub', style: TextStyle(color: AppColors.primaryText)),
          backgroundColor: AppColors.cardSurface,
          bottom: const TabBar(
            labelColor: AppColors.electricCyan,
            unselectedLabelColor: AppColors.secondaryText,
            indicatorColor: AppColors.electricCyan,
            tabs: [
              Tab(text: 'Jurnal Umum'),
              Tab(text: 'Buku Besar'),
              Tab(text: 'Neraca Saldo'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GeneralJournalView(),
            _LedgerView(),
            _TrialBalanceView(),
          ],
        ),
      ),
    );
  }
}

class _GeneralJournalView extends ConsumerWidget {
  const _GeneralJournalView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalAsync = ref.watch(generalJournalProvider);
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return journalAsync.when(
      data: (journal) {
        if (journal.isEmpty) return const Center(child: Text('Belum ada transaksi', style: TextStyle(color: AppColors.secondaryText)));

        // Group by transaction
        final Map<int, List<Map<String, dynamic>>> grouped = {};
        for (var entry in journal) {
          final id = entry['transaksi_id'];
          grouped.putIfAbsent(id, () => []).add(entry);
        }

        return ListView.builder(
          itemCount: grouped.keys.length,
          itemBuilder: (context, index) {
            final id = grouped.keys.elementAt(index);
            final entries = grouped[id]!;
            final first = entries.first;

            return Card(
              color: AppColors.cardSurface,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(first['tanggal'], style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                        const Text('#\$id', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(first['teks_asli'], style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
                    const Divider(color: AppColors.borderLine),
                    ...entries.map((e) {
                      final isDebit = (e['debit'] as num) > 0;
                      return Padding(
                        padding: EdgeInsets.only(
                          left: isDebit ? 0 : 32,
                          top: 4,
                          bottom: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e['nama_akun'], style: TextStyle(color: isDebit ? AppColors.neonMint : AppColors.secondaryText)),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                formatter.format(isDebit ? e['debit'] : e['kredit']),
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
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
  }
}

class _LedgerView extends ConsumerStatefulWidget {
  const _LedgerView();

  @override
  ConsumerState<_LedgerView> createState() => _LedgerViewState();
}

class _LedgerViewState extends ConsumerState<_LedgerView> {
  int? _selectedAccountId;

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.cardSurface,
          child: accountsAsync.when(
            data: (accounts) {
              if (accounts.isEmpty) return const SizedBox();
              _selectedAccountId ??= accounts.first.id;

              return DropdownButton<int>(
                value: _selectedAccountId,
                isExpanded: true,
                dropdownColor: AppColors.cardSurface,
                style: const TextStyle(color: AppColors.primaryText),
                items: accounts.map((Akun akun) {
                  return DropdownMenuItem<int>(
                    value: akun.id,
                    child: const Text('\${akun.kodeAkun} - \${akun.namaAkun}'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedAccountId = val);
                },
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, s) => const Text('Error', style: TextStyle(color: AppColors.laserCoral)),
          ),
        ),
        if (_selectedAccountId != null)
          Expanded(
            child: ref.watch(ledgerProvider(_selectedAccountId!)).when(
              data: (entries) {
                if (entries.isEmpty) return const Center(child: Text('Belum ada mutasi', style: TextStyle(color: AppColors.secondaryText)));

                double saldo = 0;
                final posNormal = accountsAsync.value?.firstWhere((a) => a.id == _selectedAccountId).posisiNormal ?? 'DEBIT';

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppColors.cardSurface),
                      dataRowColor: WidgetStateProperty.all(AppColors.canvasBackground),
                      dividerThickness: 1,
                      border: TableBorder.all(color: AppColors.borderLine),
                      columns: const [
                        DataColumn(label: Text('Tanggal', style: TextStyle(color: AppColors.primaryText))),
                        DataColumn(label: Text('Keterangan', style: TextStyle(color: AppColors.primaryText))),
                        DataColumn(label: Text('Debit', style: TextStyle(color: AppColors.neonMint))),
                        DataColumn(label: Text('Kredit', style: TextStyle(color: AppColors.laserCoral))),
                        DataColumn(label: Text('Saldo', style: TextStyle(color: AppColors.electricCyan))),
                      ],
                      rows: entries.map((e) {
                        final debit = (e['debit'] as num).toDouble();
                        final kredit = (e['kredit'] as num).toDouble();

                        if (posNormal == 'DEBIT') {
                          saldo += debit - kredit;
                        } else {
                          saldo += kredit - debit;
                        }

                        return DataRow(cells: [
                          DataCell(Text(e['tanggal'], style: const TextStyle(color: AppColors.secondaryText))),
                          DataCell(Text(e['teks_asli'], style: const TextStyle(color: AppColors.primaryText))),
                          _buildDataCell(debit, formatter),
                          _buildDataCell(kredit, formatter),
                          _buildDataCell(saldo, formatter),
                        ]);
                      }).toList(),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.electricCyan)),
              error: (e, s) => const Center(child: Text('Error: \$e', style: TextStyle(color: AppColors.laserCoral))),
            ),
          ),
      ],
    );
  }

  DataCell _buildDataCell(double amount, NumberFormat formatter) {
    if (amount == 0) return const DataCell(Text(''));
    return DataCell(
      Container(
        alignment: Alignment.centerRight,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            formatter.format(amount),
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrialBalanceView extends ConsumerWidget {
  const _TrialBalanceView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trialBalanceAsync = ref.watch(trialBalanceProvider);
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);

    return trialBalanceAsync.when(
      data: (balances) {
        if (balances.isEmpty) return const Center(child: Text('Belum ada data', style: TextStyle(color: AppColors.secondaryText)));

        double sumDebit = 0;
        double sumKredit = 0;

        final rows = balances.map((b) {
          final posNormal = b['posisi_normal'];
          final double tDebit = (b['total_debit'] as num).toDouble();
          final double tKredit = (b['total_kredit'] as num).toDouble();

          double saldoDebit = 0;
          double saldoKredit = 0;

          if (posNormal == 'DEBIT') {
            saldoDebit = tDebit - tKredit;
            if (saldoDebit < 0) {
              saldoKredit = saldoDebit.abs();
              saldoDebit = 0;
            }
          } else {
            saldoKredit = tKredit - tDebit;
            if (saldoKredit < 0) {
              saldoDebit = saldoKredit.abs();
              saldoKredit = 0;
            }
          }

          sumDebit += saldoDebit;
          sumKredit += saldoKredit;

          return DataRow(cells: [
            DataCell(Text(b['kode_akun'], style: const TextStyle(color: AppColors.secondaryText))),
            DataCell(Text(b['nama_akun'], style: const TextStyle(color: AppColors.primaryText))),
            _buildDataCell(saldoDebit, formatter),
            _buildDataCell(saldoKredit, formatter),
          ]);
        }).toList();

        final isBalanced = (sumDebit - sumKredit).abs() < 0.01;

        rows.add(DataRow(
          color: WidgetStateProperty.all(AppColors.cardSurface),
          cells: [
            const DataCell(Text('')),
            const DataCell(Text('TOTAL', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold))),
            _buildDataCell(sumDebit, formatter, isTotal: true, isBalanced: isBalanced),
            _buildDataCell(sumKredit, formatter, isTotal: true, isBalanced: isBalanced),
          ],
        ));

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.cardSurface),
              dataRowColor: WidgetStateProperty.all(AppColors.canvasBackground),
              dividerThickness: 1,
              border: TableBorder.all(color: AppColors.borderLine),
              columns: const [
                DataColumn(label: Text('Kode', style: TextStyle(color: AppColors.primaryText))),
                DataColumn(label: Text('Akun', style: TextStyle(color: AppColors.primaryText))),
                DataColumn(label: Text('Debit', style: TextStyle(color: AppColors.neonMint))),
                DataColumn(label: Text('Kredit', style: TextStyle(color: AppColors.laserCoral))),
              ],
              rows: rows,
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.electricCyan)),
      error: (e, s) => const Center(child: Text('Error: \$e', style: TextStyle(color: AppColors.laserCoral))),
    );
  }

  DataCell _buildDataCell(double amount, NumberFormat formatter, {bool isTotal = false, bool isBalanced = true}) {
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
              color: isTotal
                ? (isBalanced ? AppColors.neonMint : AppColors.laserCoral)
                : AppColors.primaryText,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}
