class Product {
  final String id;
  final String name;
  final int price;
  final int hpp;
  final String category;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.hpp,
    required this.category,
    this.imageUrl,
  });

  factory Product.fromMap(Map<String, dynamic> m) => Product(
        id: m['id'] as String,
        name: m['name'] as String,
        price: (m['price'] ?? 0) as int,
        hpp: (m['hpp'] ?? 0) as int,
        category: (m['category'] ?? 'Lainnya') as String,
        imageUrl: m['image_url'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price,
        'hpp': hpp,
        'category': category,
        'image_url': imageUrl,
      };
}