import 'package:flutter/material.dart';
import '../supabase_config.dart';
import 'table_picker_dialog.dart';

class CashierPage extends StatefulWidget {
  const CashierPage({super.key});

  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  List<dynamic> _activeTables = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchActiveTables();
  }

  Future<void> _fetchActiveTables() async {
    setState(() => _isLoading = true);
    try {
      // Ambil transaksi yang statusnya 'draft' beserta itemnya
      final data = await supabase
          .from('transactions')
          .select('*, transaction_items(*)')
          .eq('status', 'draft')
          .order('updated_at', ascending: false);

      if (mounted) {
        setState(() {
          _activeTables = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data meja: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meja Belum Bayar'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchActiveTables,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeTables.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada pesanan aktif.\nKlik tombol + untuk membuat pesanan baru.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _activeTables.length,
                  itemBuilder: (context, index) {
                    final tx = _activeTables[index];
                    final items = tx['transaction_items'] as List;
                    final total = tx['total_amount'];
                    
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Meja ${tx['table_number']}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Rp $total',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('${items.length} macam item'),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    // TODO: Buka halaman Edit Pesanan
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Fitur Edit segera hadir')),
                                    );
                                  },
                                  child: const Text('Edit'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    // TODO: Buka Dialog Pembayaran
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Fitur Bayar segera hadir')),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Bayar'),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // 1. Ambil daftar nomor meja yang sedang aktif (draft)
          final List<int> activeTableNumbers = _activeTables
              .map((tx) => tx['table_number'] as int)
              .toList();

          // 2. Tampilkan Pop-up Pilih Meja
          final selectedTable = await showDialog<int>(
            context: context,
            builder: (context) => TablePickerDialog(activeTables: activeTableNumbers),
          );

          // 3. Jika user memilih meja (tidak klik Batal)
          if (selectedTable != null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Membuka menu untuk Meja $selectedTable...')),
              );
              // TODO: Nanti kita arahkan ke halaman pemilihan menu (OrderPage) di sini
            }
          }
        },
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Pesanan Baru', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}