import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import 'dart:typed_data';

class AddProductPage extends StatefulWidget {
  final Product? product; // null = tambah, isi = edit
  const AddProductPage({super.key, this.product});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _hppCtrl = TextEditingController();

  String _category = 'Makanan';
  final _categories = ['Makanan', 'Minuman', 'Snack', 'Lainnya'];

XFile? _pickedImage;
Uint8List? _pickedImageBytes;                   // ✅ TAMBAHKAN BARIS INI
String? _existingImageUrl;
bool _saving = false;

  // ==== Validasi nama duplikat ====
  Timer? _debounce;
  bool _isNameDuplicate = false;
  bool _isCheckingName = false;

  final _supabase = Supabase.instance.client;
  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final p = widget.product!;
      _nameCtrl.text = p.name;
      _priceCtrl.text = _formatRupiah(p.price);
      _hppCtrl.text = _formatRupiah(p.hpp);
      _category = _categories.contains(p.category) ? p.category : 'Lainnya';
      _existingImageUrl = p.imageUrl;
    }
    _nameCtrl.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameCtrl.removeListener(_onNameChanged);
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _hppCtrl.dispose();
    super.dispose();
  }

  // ====== Utils format ribuan ======
  String _formatRupiah(int value) {
    final s = value.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }

  int _parseRupiah(String t) => int.tryParse(t.replaceAll('.', '')) ?? 0;

  TextInputFormatter _thousandFormatter() {
    return TextInputFormatter.withFunction((old, neu) {
      if (neu.text.isEmpty) return neu;
      final digits = neu.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isEmpty) return const TextEditingValue();
      final formatted = _formatRupiah(int.parse(digits));
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    });
  }

  // ====== Cek nama duplikat (debounce 500ms) ======
  void _onNameChanged() {
    final value = _nameCtrl.text.trim();
    _debounce?.cancel();

    if (value.isEmpty) {
      setState(() {
        _isNameDuplicate = false;
        _isCheckingName = false;
      });
      return;
    }
    // Saat edit dan nama tidak berubah → skip query
    if (_isEdit && value == widget.product!.name) {
      setState(() {
        _isNameDuplicate = false;
        _isCheckingName = false;
      });
      return;
    }

    setState(() => _isCheckingName = true);
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _checkDuplicate(value);
    });
  }

  Future<void> _checkDuplicate(String name) async {
    try {
      var q = _supabase.from('products').select('id').eq('name', name);
      if (_isEdit) q = q.neq('id', widget.product!.id);
      final data = await q.maybeSingle();
      if (!mounted) return;
      setState(() {
        _isNameDuplicate = data != null;
        _isCheckingName = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCheckingName = false);
    }
  }

  // ====== Upload gambar ======
  Future<void> _pickImage() async {
  final f = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    imageQuality: 70,
  );
  if (f == null) return;
  final bytes = await f.readAsBytes();
  if (!mounted) return;
  setState(() {
    _pickedImage = f;
    _pickedImageBytes = bytes;                  // ✅ simpan bytes
  });
}

  Future<String?> _uploadImage() async {
  if (_pickedImageBytes == null) return _existingImageUrl;
  
  final ext = _pickedImage!.name.split('.').last.toLowerCase();
  final path = '${DateTime.now().millisecondsSinceEpoch}.$ext';
  
  String contentType = 'image/jpeg'; // default
  if (ext == 'png') contentType = 'image/png';
  if (ext == 'webp') contentType = 'image/webp';
  if (ext == 'gif') contentType = 'image/gif';

  await _supabase.storage.from('product-images').uploadBinary(
        path,
        _pickedImageBytes!,
        fileOptions: FileOptions(contentType: contentType), 
      );
  return _supabase.storage.from('product-images').getPublicUrl(path);
}

  // ====== Simpan ======
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isNameDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama produk sudah digunakan')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final imageUrl = await _uploadImage();
      final data = {
        'name': _nameCtrl.text.trim(),
        'price': _parseRupiah(_priceCtrl.text),
        'hpp': _parseRupiah(_hppCtrl.text),
        'category': _category,
        'image_url': imageUrl,
      };

      // ====== BAGIAN YANG DIUBAH ======
      if (_isEdit) {
        // Menambahkan .select() untuk mendeteksi jika RLS memblokir
        final res = await _supabase
            .from('products')
            .update(data)
            .eq('id', widget.product!.id)
            .select();
        
        if (res.isEmpty) {
          throw Exception('Akses ditolak atau data tidak ditemukan (cek RLS)');
        }
      } else {
        // Menambahkan .select() untuk mendeteksi jika RLS memblokir
        final res = await _supabase
            .from('products')
            .insert(data)
            .select();
            
        if (res.isEmpty) {
          throw Exception('Akses ditolak (cek RLS)');
        }
      }
      // =================================

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Produk' : 'Tambah Produk'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==== Nama Produk ====
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Produk',
                  border: const OutlineInputBorder(),
                  errorText: _isNameDuplicate
                      ? 'Nama produk sudah digunakan'
                      : null,
                  suffixIcon: _isCheckingName
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : (_isNameDuplicate
                          ? const Icon(Icons.error, color: Colors.red)
                          : null),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Nama wajib diisi';
                  }
                  if (_isNameDuplicate) {
                    return 'Nama produk sudah digunakan';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // ==== Harga Jual ====
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [_thousandFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Harga Jual (Rp)',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
                validator: (v) =>
                    _parseRupiah(v ?? '') <= 0 ? 'Harga wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              // ==== HPP ====
              TextFormField(
                controller: _hppCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [_thousandFormatter()],
                decoration: const InputDecoration(
                  labelText: 'HPP / Modal (Rp)',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                  helperText: 'Harga pokok pembelian/harga modal',
                ),
              ),
              const SizedBox(height: 12),

              // ==== Kategori ====
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),

              // ==== Gambar ====
              Container(
                height: 140,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InkWell(
                  onTap: _pickImage,
                  child: _pickedImageBytes != null
    ? ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          _pickedImageBytes!,
          fit: BoxFit.cover,
        ),
      )
                      : (_existingImageUrl != null
                          ? Image.network(_existingImageUrl!, fit: BoxFit.cover)
                          : const Center(
                              child: Icon(Icons.add_a_photo, size: 40),
                            )),
                ),
              ),
              const SizedBox(height: 24),

              // ==== Tombol simpan ====
              FilledButton(
                onPressed: _saving || _isNameDuplicate ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEdit ? 'Simpan Perubahan' : 'Simpan Produk'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}