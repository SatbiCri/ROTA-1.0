import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/colors.dart';
import '../../data/models.dart';
import '../../providers/accounting_providers.dart';
import '../../providers/inference_provider.dart';
import '../../providers/transaction_provider.dart';

class SmartInputScreen extends ConsumerStatefulWidget {
  const SmartInputScreen({super.key});

  @override
  ConsumerState<SmartInputScreen> createState() => _SmartInputScreenState();
}

class _SmartInputScreenState extends ConsumerState<SmartInputScreen> {
  final TextEditingController _textController = TextEditingController();
  int? _selectedDebitId;
  int? _selectedCreditId;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inferenceState = ref.watch(inferenceStateProvider);
    final accountsAsyncValue = ref.watch(accountsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: AppBar(
        title: const Text('Smart Input', style: TextStyle(color: AppColors.primaryText)),
        backgroundColor: AppColors.cardSurface,
      ),
      body: accountsAsyncValue.when(
        data: (accounts) {
          if (_selectedDebitId == null && inferenceState.suggestedDebitAccountId != 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedDebitId = inferenceState.suggestedDebitAccountId);
            });
          }
          if (_selectedCreditId == null && inferenceState.suggestedCreditAccountId != 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedCreditId = inferenceState.suggestedCreditAccountId);
            });
          }

          final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

          bool isSaveEnabled = inferenceState.nominal > 0 &&
              _selectedDebitId != null &&
              _selectedCreditId != null &&
              _selectedDebitId != _selectedCreditId;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _textController,
                  style: const TextStyle(color: AppColors.primaryText),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: AppColors.inputSurface,
                    hintText: 'Misal: Beli ATK 50000',
                    hintStyle: TextStyle(color: AppColors.secondaryText),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.borderLine),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.electricCyan),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedDebitId = null;
                      _selectedCreditId = null;
                    });
                    ref.read(inferenceStateProvider.notifier).onInputChanged(value);
                  },
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (inferenceState.nominal > 0)
                      Chip(
                        label: Text(formatter.format(inferenceState.nominal)),
                        backgroundColor: AppColors.neonMint.withOpacity(0.2),
                        labelStyle: const TextStyle(color: AppColors.neonMint),
                      ),
                    if (inferenceState.extractedKeyword.isNotEmpty)
                      Chip(
                        label: Text(inferenceState.extractedKeyword),
                        backgroundColor: AppColors.cyberViolet.withOpacity(0.2),
                        labelStyle: const TextStyle(color: AppColors.cyberViolet),
                      ),
                    if (inferenceState.suggestedDebitAccountId != 0)
                      Chip(
                        label: Text(inferenceState.isFromKnowledgeCache ? 'Memory Cache' : 'Vector Inference'),
                        backgroundColor: (inferenceState.isFromKnowledgeCache ? AppColors.neonMint : AppColors.cyberViolet).withOpacity(0.2),
                        labelStyle: TextStyle(color: inferenceState.isFromKnowledgeCache ? AppColors.neonMint : AppColors.cyberViolet),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          border: Border.all(color: AppColors.borderLine),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Debit', style: TextStyle(color: AppColors.secondaryText)),
                            DropdownButton<int>(
                              value: _selectedDebitId,
                              isExpanded: true,
                              dropdownColor: AppColors.cardSurface,
                              style: const TextStyle(color: AppColors.primaryText),
                              items: accounts.map((Akun akun) {
                                return DropdownMenuItem<int>(
                                  value: akun.id,
                                  child: Text(akun.namaAkun, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDebitId = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          border: Border.all(color: AppColors.borderLine),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Kredit', style: TextStyle(color: AppColors.secondaryText)),
                            DropdownButton<int>(
                              value: _selectedCreditId,
                              isExpanded: true,
                              dropdownColor: AppColors.cardSurface,
                              style: const TextStyle(color: AppColors.primaryText),
                              items: accounts.map((Akun akun) {
                                return DropdownMenuItem<int>(
                                  value: akun.id,
                                  child: Text(akun.namaAkun, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCreditId = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isSaveEnabled
                      ? () async {
                          await ref.read(transactionProvider).saveTransaction(
                                teksAsli: _textController.text,
                                nominal: inferenceState.nominal,
                                selectedDebitId: _selectedDebitId!,
                                selectedCreditId: _selectedCreditId!,
                                extractedKeyword: inferenceState.extractedKeyword,
                              );
                          _textController.clear();
                          ref.read(inferenceStateProvider.notifier).clear();
                          setState(() {
                            _selectedDebitId = null;
                            _selectedCreditId = null;
                          });
                          // Refresh accounts provider if needed or let Riverpod auto-refresh dependent providers
                          if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Transaksi Berhasil Disimpan')),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricCyan,
                    disabledBackgroundColor: AppColors.borderLine,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Simpan Transaksi', style: TextStyle(color: AppColors.canvasBackground, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.electricCyan)),
        error: (err, stack) => const Center(child: Text('Error: \$err', style: TextStyle(color: AppColors.laserCoral))),
      ),
    );
  }
}
