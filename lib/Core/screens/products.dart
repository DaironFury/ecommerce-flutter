import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../provider/provider.dart';
import 'product_detail.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  bool _isSyncing = false;

  Future<void> _syncProducts() async {
    setState(() => _isSyncing = true);
    try {
      await ref.read(firestoreServiceProvider).syncWithExternalApi();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Productos sincronizados correctamente')),
      );
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsStream = ref.watch(firestoreServiceProvider).getProductsStream();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _isSyncing ? null : _syncProducts,
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: productsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No hay productos disponibles'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isSyncing ? null : _syncProducts,
                    child: _isSyncing
                        ? const CircularProgressIndicator()
                        : const Text('Sincronizar productos'),
                  ),
                ],
              ),
            );
          }

          final products = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.7,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final price = (product['price'] as num).toDouble();
              
              return ProductCard(
                productId: product.id,
                name: product['name'],
                price: price,
                imageUrl: product['imageUrl'],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(
                      productId: product.id,
                      isFromApi: product['fromApi'] ?? false,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String productId;
  final String name;
  final double price;
  final String imageUrl;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text('\$${price.toStringAsFixed(2)}'), // Muestra siempre 2 decimales
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}