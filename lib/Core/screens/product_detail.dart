import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../provider/provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  final bool isFromApi;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.isFromApi = false,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int quantity = 1;
  Map<String, dynamic>? _apiProductDetails;

  @override
  void initState() {
    super.initState();
    if (widget.isFromApi) {
      _loadApiDetails();
    }
  }

  Future<void> _loadApiDetails() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final details = await apiService.fetchProductDetails(int.parse(widget.productId));
      setState(() => _apiProductDetails = details);
    } catch (e) {
      print('Error loading API details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isFromApi && _apiProductDetails != null) {
      return _buildApiProductDetail();
    }

    final productFuture = ref.watch(firestoreServiceProvider).getProduct(widget.productId);

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: productFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Producto no encontrado'));
        }

        final product = snapshot.data!;
        final data = product.data()!;
        final price = (data['price'] as num).toDouble();
        final stock = data['stock'] as int;

        return _buildProductDetail(
          name: data['name'],
          description: data['description'],
          price: price,
          imageUrl: data['imageUrl'],
          category: data['category'],
          stock: stock,
        );
      },
    );
  }

  Widget _buildApiProductDetail() {
    final details = _apiProductDetails!;
    return _buildProductDetail(
      name: details['title'],
      description: details['description'],
      price: (details['price'] as num).toDouble(),
      imageUrl: details['image'],
      category: details['category'],
      stock: 100, // Valor por defecto para API
    );
  }

  Widget _buildProductDetail({
    required String name,
    required String description,
    required double price,
    required String imageUrl,
    required String category,
    required int stock,
  }) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalles del Producto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 300,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '\$${price.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Descripción:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(description),
            const SizedBox(height: 16),
            Text('Categoría: ${category.capitalize()}'),
            const SizedBox(height: 16),
            Text('Disponibles: $stock'),
            const SizedBox(height: 24),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: quantity > 1
                      ? () => setState(() => quantity--)
                      : null,
                ),
                Text(quantity.toString(), style: const TextStyle(fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: quantity < stock
                      ? () => setState(() => quantity++)
                      : null,
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    ref.read(firestoreServiceProvider)
                      .addToCart(widget.productId, quantity);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Producto añadido al carrito')),
                    );
                  },
                  child: const Text('Añadir al carrito'),
                ),
              ],
            ),
            if (widget.isFromApi) 
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('Producto de FakeStoreAPI', 
                  style: TextStyle(fontStyle: FontStyle.italic)),
              ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}