import 'package:flutter/material.dart';
import '../supabase_config.dart';
import '../models/cart_item.dart';
import 'cashier_page.dart';

class OrderPage extends StatefulWidget {
  final int tableNumber;
  /// Null = mode "buat baru", Non-null = mode "edit draft"
  final int? transactionId;
  /// Wajib diisi jika [transactionId] tidak null (data dari transaction_items)
  final List<dynamic>? initialItems;

  const OrderPage({
    super.key,
    required this.tableNumber,
    this.transactionId,
    this.initialItems,
  });

  bool get isEditing => transactionId != null;

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  List<dynamic> _products = [];
  List<CartItem> _cart = [];
  bool _isLoading = true;
  String _selectedCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    // Pre-fill cart jika mode edit
    if (widget.isEditing && widget.initialItems != null) {
      _cart = widget.initialItems!.map((item) {
        return CartItem(
          id: item['product_id'],
          name: item['product_name'],
          price: double.parse(item['price'].toString()),
          quantity: item['quantity'] as int,
        );
      }).toList();
    }
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final data = await supabase.from('products').select().order('name');
      if (mounted) {
        setState(() {
          _products = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat produk: $e')),
        );
      }
    }
  }

  void _addToCart(dynamic product) {
    setState(() {
      final index = _cart.indexWhere((item) => item.id == product['id']);
      if (index >= 0) {
        _cart[index].quantity++;
      } else {
        _cart.add(CartItem(
          id: product['id'],
          name: product['name'],
          price: double.parse(product['price'].toString()),
          quantity: 1,
        ));
      }
    });
  }

  void _removeFromCart(CartItem item) {
    setState(() {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        _cart.remove(item);
      }
    });
  }

  double get _totalAmount => _cart.fold(0, (sum, item) => sum + item.subtotal);

  Future<void> _saveOrder() async {
    if (_cart.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      if (widget.isEditing) {
        // === UPDATE DRAFT ===
        await supabase.rpc('update_draft_items', params: {
  'p_tx_id': widget.transactionId,
  'p_items': _cart.map((e) => e.toMap()).toList(),
}); 

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pesanan Meja ${widget.tableNumber} berhasil diperbarui!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // return true agar cashier refresh
        }
      } else {
        // === CREATE BARU ===
        await supabase.rpc('create_transaction', params: {
          'p_items': _cart.map((e) => e.toMap()).toList(),
          'p_table_number': widget.tableNumber,
          'p_payment_method': 'cash',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pesanan Meja ${widget.tableNumber} berhasil disimpan!'),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan pesanan: $e')),
        );
      }
    }
  }

  void _showCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
  bottom: MediaQuery.of(context).viewInsets.bottom + 16, // <-- Perhatikan tambahan + 16 di sini
  left: 16, right: 16, top: 16,
),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.isEditing ? 'Update Pesanan' : 'Konfirmasi Pesanan',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (_cart.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Keranjang masih kosong'),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _cart.length,
                        itemBuilder: (context, index) {
                          final item = _cart[index];
                          return ListTile(
                            title: Text(item.name),
                            subtitle: Text('Rp ${item.price.toStringAsFixed(0)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    _removeFromCart(item);
                                    setModalState(() {});
                                    setState(() {});
                                  },
                                ),
                                Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () {
                                    _addToCart({'id': item.id, 'name': item.name, 'price': item.price});
                                    setModalState(() {});
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Rp ${_totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _cart.isEmpty || _isLoading ? null : () {
                        Navigator.pop(context); // Tutup bottom sheet
                        _saveOrder();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isEditing ? Colors.orange[700] : const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              widget.isEditing ? 'Update Pesanan' : 'Simpan Pesanan',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['Semua', ..._products.map((p) => p['category'] ?? 'Lainnya').toSet()];
    final filteredProducts = _selectedCategory == 'Semua'
        ? _products
        : _products.where((p) => (p['category'] ?? 'Lainnya') == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing
            ? 'Edit Meja ${widget.tableNumber}'
            : 'Meja ${widget.tableNumber}'),
        backgroundColor: widget.isEditing ? Colors.orange[700] : const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: _isLoading && _products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedCategory = cat);
                          },
                          selectedColor: Colors.blue[100],
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final imageUrl = product['image_url'];

                      return Card(
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _addToCart(product),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: imageUrl != null && imageUrl.isNotEmpty
                                    ? Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity)
                                    : Container(
                                        color: Colors.grey[200],
                                        width: double.infinity,
                                        child: const Icon(Icons.fastfood, size: 50, color: Colors.grey),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['name'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rp ${product['price']}',
                                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _cart.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _showCartBottomSheet,
              backgroundColor: widget.isEditing ? Colors.orange[700] : Colors.green,
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              label: Text(
                '${_cart.fold(0, (sum, item) => sum + item.quantity)} Item • Rp ${_totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
    );
  }
}