import 'package:flutter/material.dart';
import '../supabase_config.dart';
import 'package:flutter/services.dart';

class PaymentDialog extends StatefulWidget {
  final int transactionId;
  final int tableNumber;
  final double totalAmount;

  const PaymentDialog({
    super.key,
    required this.transactionId,
    required this.tableNumber,
    required this.totalAmount,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
final TextEditingController _cashController = TextEditingController();
bool _isLoading = false;

@override
void dispose() {                              // ✅ METHOD BARU
  _cashController.dispose();
  super.dispose();
}

double get _cashReceived {
  final cleaned = _cashController.text.replaceAll(RegExp(r'[^0-9]'), '');
  return double.tryParse(cleaned) ?? 0;
}
  double get _change => _cashReceived - widget.totalAmount;

  Future<void> _processPayment() async {
    if (_cashReceived < widget.totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uang tunai kurang!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Panggil RPC pay_transaction yang sudah kita buat di database
      await supabase.rpc('pay_transaction', params: {
        'p_tx_id': widget.transactionId,
        'p_amount_paid': _cashReceived,
      });

      if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Pembayaran Meja ${widget.tableNumber} Berhasil! Kembalian: Rp ${_change.toStringAsFixed(0)}',
      ),
      backgroundColor: Colors.green,
    ),
  );
  Navigator.pop(context, true);
}
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses pembayaran: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Bayar - Meja ${widget.tableNumber}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Tagihan:', style: TextStyle(fontSize: 14)),
          Text(
            'Rp ${widget.totalAmount.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 16),
          TextField(
  controller: _cashController,
  keyboardType: TextInputType.number,
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
  ],
  decoration: const InputDecoration(
    labelText: 'Uang Tunai Diterima',
    border: OutlineInputBorder(),
    prefixText: 'Rp ',
  ),
  onChanged: (value) => setState(() {}),
),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kembalian:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                'Rp ${_change < 0 ? 0 : _change.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: _change < 0 ? Colors.grey : Colors.green
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading || _cashReceived < widget.totalAmount ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Konfirmasi Bayar'),
        ),
      ],
    );
  }
}