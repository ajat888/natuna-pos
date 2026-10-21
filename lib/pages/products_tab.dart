import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import 'add_product_page.dart';
import 'login_page.dart';

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  final _supabase = Supabase.instance.client;
  final _searchCtrl = TextEditingController();

  List<Product> _all = [];
  bool _loading = true;
  String _selectedCategory = 'Semua';
  final _categories = ['Semua', 'Makanan', 'Minuman', 'Snack', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _supabase
          .from('products')
          .select()
          .order('name', ascending: true); // A-Z
      setState(() {
        _all = (data as List).map((e) => Product.fromMap(e)).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat produk: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Product> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _all.where((p) {
      final okCat =
          _selectedCategory == 'Semua' || p.category == _selectedCategory;
      final okSearch = q.isEmpty || p.name.toLowerCase().contains(q);
      return okCat && okSearch;
    }).toList();
  }

  Future<void> _openAdd() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddProductPage()),
    );
    if (changed == true) _load();
  }

  Future<void> _openEdit(Product p) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddProductPage(product: p)),
    );
    if (changed == true) _load();
  }

  Future<void> _confirmDelete(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Yakin ingin menghapus "${p.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    
    try {
      // PERUBAHAN DI SINI: Tambahkan .select() untuk mendeteksi RLS
      final res = await _supabase
          .from('products')
          .delete()
          .eq('id', p.id)
          .select();

      if (!mounted) return;

      if (res.isEmpty) {
        // Jika kosong, berarti RLS memblokir atau ID tidak ditemukan
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus: Akses ditolak (cek RLS)')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk dihapus')),
        );
        _load(); // Refresh grid jika berhasil
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal hapus: $e')),
        );
      }
    }
  }

  void _showActions(Product p) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Produk'),
              onTap: () {
                Navigator.pop(ctx);
                _openEdit(p);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Hapus Produk',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(p);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatRp(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return 'Rp ${b.toString()}';
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Produk'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // ==== Search ====
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchCtrl.clear(),
                      )
                    : null,
              ),
            ),
          ),

          // ==== ChoiceChip kategori ====
          SizedBox(
            height: 50,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = _categories[i];
                return ChoiceChip(
                  label: Text(c),
                  selected: _selectedCategory == c,
                  onSelected: (_) => setState(() => _selectedCategory = c),
                );
              },
            ),
          ),

          // ==== Grid ====
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada produk',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: products.length,
                          itemBuilder: (_, i) {
                            final p = products[i];
                            return _ProductCard(
                              product: p,
                              formatRp: _formatRp,
                              onTap: () => _showActions(p),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final String Function(int) formatRp;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.formatRp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: product.imageUrl != null
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Color(0xFFEEEEEE),
                        child: Icon(Icons.image_not_supported, size: 40),
                      ),
                    )
                  : const ColoredBox(
                      color: Color(0xFFEEEEEE),
                      child: Icon(Icons.image, size: 40),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                product.category,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatRp(product.price),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'HPP: ${formatRp(product.hpp)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}