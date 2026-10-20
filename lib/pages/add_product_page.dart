import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../supabase_config.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  
  // List Kategori Default
  List<String> _categories = ['Makanan', 'Minuman', 'Paket', 'Lainnya'];
  String? _selectedCategory = 'Makanan';
  
  // Variabel untuk Gambar
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // --- FUNGSI FORMAT HARGA (35.000) ---
  String _formatRupiah(int value) {
    return value.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  void _onPriceChanged(String value) {
    // Hapus semua titik untuk mendapatkan angka murni
    String cleanText = value.replaceAll('.', '');
    if (cleanText.isEmpty) return;

    int? parsed = int.tryParse(cleanText);
    if (parsed != null) {
      // Format ulang dengan titik
      String formatted = _formatRupiah(parsed);
      
      // Update controller text tanpa memindahkan kursor ke awal
      _priceController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  // --- FUNGSI PILIH GAMBAR ---
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Kompres agar upload cepat
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    }
  }

  // --- FUNGSI TAMBAH KATEGORI BARU ---
  void _addNewCategory() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Kategori Baru'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nama Kategori',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final newCat = controller.text.trim();
              if (newCat.isNotEmpty && !_categories.contains(newCat)) {
                setState(() {
                  _categories.add(newCat);
                  _selectedCategory = newCat;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan Harga wajib diisi!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;

      // 1. Upload Gambar jika ada
      if (_selectedImageBytes != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('product-images').uploadBinary(fileName, _selectedImageBytes!);
        
        // 2. Ambil URL Publiknya
        imageUrl = supabase.storage.from('product-images').getPublicUrl(fileName);
      }

      // 3. Bersihkan harga dari titik untuk disimpan ke DB
      String cleanPrice = _priceController.text.replaceAll('.', '');

      // 4. Simpan ke Database
      await supabase.from('products').insert({
        'name': _nameController.text.trim(),
        'price': int.parse(cleanPrice),
        'stock': 0, // Stok dihardcode 0 karena dihilangkan dari form
        'category': _selectedCategory,
        'image_url': imageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk berhasil ditambahkan!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambah produk: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Produk Baru'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Nama Produk
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Produk', 
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.fastfood),
              ),
            ),
            const SizedBox(height: 16),

            // Kategori & Tombol +
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedCategory = val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 56, // Samakan tinggi dengan TextField
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    tooltip: 'Tambah Kategori',
                    onPressed: _addNewCategory,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Harga (Auto Format)
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              onChanged: _onPriceChanged,
              decoration: const InputDecoration(
                labelText: 'Harga (Rp)', 
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money),
              ),
            ),
            const SizedBox(height: 16),

            // Upload Gambar
            InkWell(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedImageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _selectedImageBytes!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Pilih Gambar dari Galeri', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 32),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SIMPAN PRODUK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}