import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class ApiService {
  static const String _baseUrl = 'https://fakestoreapi.com';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> fetchAndSyncProducts() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/products'));
      if (response.statusCode == 200) {
        final List<dynamic> products = json.decode(response.body);
        
        // Sincronizar con Firestore
        final batch = _firestore.batch();
        final productsCollection = _firestore.collection('products');

        for (final product in products) {
          final docRef = productsCollection.doc(product['id'].toString());
          batch.set(docRef, {
            'name': product['title'],
            'description': product['description'],
            'price': product['price'],
            'imageUrl': product['image'],
            'category': product['category'],
            'stock': 100, // Valor por defecto
            'createdAt': FieldValue.serverTimestamp(),
            'fromApi': true, // Marcar como producto de la API
          });
        }

        await batch.commit();
      }
    } catch (e) {
      print('Error fetching/syncing products: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/products'));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      throw Exception('Failed to load products');
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> fetchProductDetails(int productId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/products/$productId'));
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to load product details');
    } catch (e) {
      print('Error fetching product details: $e');
      return {};
    }
  }
}