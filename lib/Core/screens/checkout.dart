import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/provider.dart';

class CheckoutScreen extends ConsumerWidget {
  final double total;
  final List<Map<String, dynamic>> items;

  const CheckoutScreen({
    super.key,
    required this.total,
    required this.items,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestoreService = ref.watch(firestoreServiceProvider);
    final TextEditingController addressController = TextEditingController();
    final TextEditingController paymentController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Finalizar Compra')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de la Compra',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Productos: ${items.length}'),
            Text('Total: \$${total.toStringAsFixed(2)}'),
            const SizedBox(height: 24),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Dirección de Envío',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: paymentController,
              decoration: const InputDecoration(
                labelText: 'Método de Pago',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (addressController.text.isEmpty ||
                      paymentController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Por favor complete todos los campos')),
                    );
                    return;
                  }

                  firestoreService.createOrder(items, total);
                  Navigator.popUntil(context, (route) => route.isFirst);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Pedido realizado con éxito')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                ),
                child: const Text('Confirmar Pedido'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}