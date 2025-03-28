import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../provider/provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersStream = ref.watch(firestoreServiceProvider).getUserOrdersStream();

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Pedidos')),
      body: StreamBuilder<QuerySnapshot>(
        stream: ordersStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No tienes pedidos realizados'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final order = snapshot.data!.docs[index];
              final data = order.data() as Map<String, dynamic>;
              final items = data['items'] as List<dynamic>;
              final total = data['total'] as double;
              final status = data['status'] as String;
              final date = (data['createdAt'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.all(8),
                child: ExpansionTile(
                  title: Text('Pedido #${order.id.substring(0, 8)}'),
                  subtitle: Text(
                      '${date.day}/${date.month}/${date.year} - Total: \$${total.toStringAsFixed(2)}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estado: $status'),
                          const SizedBox(height: 8),
                          const Text('Productos:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          ...items.map((item) => Text(
                              '- ${item['productId']} x ${item['quantity']}')),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}