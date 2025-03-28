import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_services.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiService _apiService = ApiService();

  // Productos
  Stream<QuerySnapshot<Map<String, dynamic>>> getProductsStream() {
    return _firestore.collection('products')
      .orderBy('createdAt', descending: true)
      .snapshots();
  }

  Future<void> syncWithExternalApi() async {
    await _apiService.fetchAndSyncProducts();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getProduct(String productId) {
    return _firestore.collection('products').doc(productId).get();
  }

  Future<void> addProduct({
    required String name,
    required String description,
    required num price,
    required String imageUrl,
    required String category,
    required int stock,
  }) async {
    await _firestore.collection('products').add({
      'name': name,
      'description': description,
      'price': price.toDouble(), // Aseguramos que sea double
      'imageUrl': imageUrl,
      'category': category,
      'stock': stock,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Carrito
  Future<void> addToCart(String productId, int quantity) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final cartRef = _firestore.collection('cart').doc(userId);
    final itemsRef = cartRef.collection('items');

    final query = await itemsRef.where('productId', isEqualTo: productId).get();
    
    if (query.docs.isNotEmpty) {
      await itemsRef.doc(query.docs.first.id).update({
        'quantity': FieldValue.increment(quantity),
      });
    } else {
      await itemsRef.add({
        'productId': productId,
        'quantity': quantity,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> removeFromCart(String itemId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('cart')
        .doc(userId)
        .collection('items')
        .doc(itemId)
        .delete();
  }

  Future<void> updateCartItemQuantity(String itemId, int newQuantity) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('cart')
        .doc(userId)
        .collection('items')
        .doc(itemId)
        .update({'quantity': newQuantity});
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCartItemsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return const Stream.empty();

    return _firestore
        .collection('cart')
        .doc(userId)
        .collection('items')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }

  // Pedidos
  Future<void> createOrder(List<Map<String, dynamic>> items, double total) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('orders').add({
      'userId': userId,
      'items': items,
      'total': total,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Vaciar el carrito
    await _firestore.collection('cart').doc(userId).collection('items').get()
      .then((snapshot) => Future.wait(snapshot.docs.map((doc) => doc.reference.delete())));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserOrdersStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return const Stream.empty();

    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}