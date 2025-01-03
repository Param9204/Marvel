import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/order.dart'; // Ensure this path is correct

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Add a new city to Firestore using the city name as the document ID
  Future<void> addCity(String cityName) async {
    try {
      await _db.collection('cities').doc(cityName).set({
        'name': cityName,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error adding city: $e");
    }
  }

  /// Delete a city from Firestore using the city name as the document ID
  Future<void> deleteCity(String cityName) async {
    try {
      await _db.collection('cities').doc(cityName).delete();
    } catch (e) {
      print("Error deleting city: $e");
    }
  }

  /// Retrieve all cities from Firestore
  Stream<List<Map<String, dynamic>>> getCities() {
    return _db
        .collection('cities')
        .orderBy('created_at')
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList());
  }


  /// Add a product order to Firestore
  Future<void> addProductOrder(
      String cityName, String shopName, ProductOrder order) async {
    try {
      final orderRef = _db
          .collection('cities')
          .doc(cityName)
          .collection('shops')
          .doc(shopName)
          .collection('orders')
          .doc();

      final updatedOrder = order.copyWith(orderId: orderRef.id);  // Set orderId using copyWith

      // Set the order in Firestore
      await orderRef.set(updatedOrder.toMap());
      print("Order created with orderId: ${updatedOrder.orderId}");
    } catch (e) {
      print('Error adding product order: $e');
    }
  }

  /// Get product orders for a shop as a stream
  Stream<List<ProductOrder>> getProductOrders(String cityName, String shopName) {
    return _db
        .collection('cities')
        .doc(cityName)
        .collection('shops')
        .doc(shopName)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final order = ProductOrder.fromMap(data);
        print("Fetched order with orderId: ${order.orderId}");  // Check orderId here
        return order;
      }).toList();
    });
  }

  Future<void> updateProductOrder(ProductOrder order) async {
    try {
      // Reference the document of the existing order
      final orderRef = _db
          .collection('cities')
          .doc(order.cityName)
          .collection('shops')
          .doc(order.shopName)
          .collection('orders')
          .doc(order.orderId);  // Use the existing orderId

      // Ensure orderId is included in the map (it should already be)
      await orderRef.update(order.toMap());
      print("Order updated with orderId: ${order.orderId}");
    } catch (e) {
      print('Error updating product order: $e');
    }
  }


  /// Update order status
  Future<void> updateOrderStatus(
      String cityName, String shopName, String orderId, String newStatus) async {
    try {
      final orderRef = _db
          .collection('cities')
          .doc(cityName)
          .collection('shops')
          .doc(shopName)
          .collection('orders')
          .doc(orderId);

      await orderRef.update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(), // Optional: Store the update time
      });
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }

  /// Delete a product order
  Future<void> deleteProductOrder(
      String cityName, String shopName, String orderId) async {
    try {
      final orderRef = _db
          .collection('cities')
          .doc(cityName)
          .collection('shops')
          .doc(shopName)
          .collection('orders')
          .doc(orderId);

      await orderRef.delete();
    } catch (e) {
      print('Error deleting product order: $e');
      rethrow;
    }
  }
}
