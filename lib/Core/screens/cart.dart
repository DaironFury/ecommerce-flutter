import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../provider/provider.dart';
import 'checkout.dart';


class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItemsStream = ref.watch(firestoreServiceProvider).getCartItemsStream();
    final firestoreService = ref.watch(firestoreServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Carrito de Compras')),
      body: StreamBuilder<QuerySnapshot>(
        stream: cartItemsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Tu carrito está vacío'));
          }

          final items = snapshot.data!.docs;
          double total = 0;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return FutureBuilder<DocumentSnapshot>(
                      future: firestoreService.getProduct(item['productId']),
                      builder: (context, productSnapshot) {
                        if (productSnapshot.connectionState == ConnectionState.waiting) {
                          return const ListTile(
                            leading: CircularProgressIndicator(),
                            title: Text('Cargando...'),
                          );
                        }

                        if (!productSnapshot.hasData || !productSnapshot.data!.exists) {
                          return const ListTile(
                            leading: Icon(Icons.error),
                            title: Text('Producto no encontrado'),
                          );
                        }

                        final product = productSnapshot.data!;
                        final productData = product.data() as Map<String, dynamic>;
                        final itemQuantity = item['quantity'];
                        final itemPrice = productData['price'] * itemQuantity;
                        total += itemPrice;

                        return Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            firestoreService.removeFromCart(item.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Producto eliminado del carrito')),
                            );
                          },
                          child: ListTile(
                            leading: CachedNetworkImage(
                              imageUrl: productData['imageUrl'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                            title: Text(productData['name']),
                            subtitle: Text(
                                'Cantidad: $itemQuantity - \$${(productData['price'] * itemQuantity).toStringAsFixed(2)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: itemQuantity > 1
                                      ? () => firestoreService.updateCartItemQuantity(
                                          item.id, itemQuantity - 1)
                                      : null,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => firestoreService.updateCartItemQuantity(
                                      item.id, itemQuantity + 1),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: \$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final orderItems = items.map((item) {
                          return {
                            'productId': item['productId'],
                            'quantity': item['quantity'],
                          };
                        }).toList();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CheckoutScreen(
                              total: total,
                              items: orderItems,
                            ),
                          ),
                        );
                      },
                      child: const Text('Finalizar Compra'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}