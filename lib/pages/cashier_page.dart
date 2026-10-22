import 'package:flutter/material.dart';
import '../supabase_config.dart';
import 'table_picker_dialog.dart';
import 'order_page.dart';
import 'payment_dialog.dart';

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

Future<void> _cancelOrder(int transactionId, int tableNumber) async {
  // 1. Tampilkan Dialog Konfirmasi
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Batalkan Pesanan?'),
      content: Text('Pesanan untuk Meja $tableNumber akan dihapus permanen. Lanjutkan?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Tidak'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Ya, Batalkan'),
        ),
      ],
    ),
  );

  // Jika user klik "Tidak" atau menutup dialog, hentikan proses
  if (confirm != true) return;

  // 2. Panggil RPC di Supabase
  setState(() => _isLoading = true); // Tampilkan loading
  try {
    await supabase.rpc('cancel_transaction', params: {
      'p_tx_id': transactionId,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pesanan Meja $tableNumber berhasil dibatalkan'),
          backgroundColor: Colors.red,
        ),
      );
      _fetchActiveTables(); // Refresh list
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membatalkan pesanan: $e')),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () => _cancelOrder(tx['id'], tx['table_number']),
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            label: const Text('Batal', style: TextStyle(color: Colors.red)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                          Row(
                            children: [
                              OutlinedButton(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderPage(
                                        tableNumber: tx['table_number'],
                                        transactionId: tx['id'],
                                        initialItems: items,
                                      ),
                                    ),
                                  );
                                  _fetchActiveTables();
                                },
                                child: const Text('Edit'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
  onPressed: () async {
    final totalRaw = tx['total_amount'];
    final total = totalRaw is num
        ? totalRaw.toDouble()
        : double.tryParse(totalRaw?.toString() ?? '') ?? 0;

    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data transaksi tidak valid. Hubungi admin.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final isPaid = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(
        transactionId: tx['id'],
        tableNumber: tx['table_number'] as num,
        totalAmount: total,
      ),
    );
    if (isPaid == true) {
      _fetchActiveTables();
    }
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
    foregroundColor: Colors.white,
  ),
  child: const Text('Bayar'),
),
                            ],
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
          final List<int> activeTableNumbers = _activeTables
              .map((tx) => tx['table_number'] as int)
              .toList();

          final selectedTable = await showDialog<int>(
            context: context,
            builder: (context) => TablePickerDialog(activeTables: activeTableNumbers),
          );

          if (selectedTable != null) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderPage(tableNumber: selectedTable),
              ),
            );
            _fetchActiveTables();
          }
        },
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Pesanan Baru', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}