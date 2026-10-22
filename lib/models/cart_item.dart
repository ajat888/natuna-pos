class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  double get subtotal => price * quantity;

  // Untuk dikirim ke Supabase RPC (JSONB)
  Map<String, dynamic> toMap() {
    return {
      'product_id': id,
      'quantity': quantity,
    };
  }
}