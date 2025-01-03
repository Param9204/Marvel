// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:factory1/model/order.dart'; // Ensure the import points to the correct file where ProductOrder is defined
// //
// // class FirestoreService {
// //   final FirebaseFirestore _db = FirebaseFirestore.instance;
// //
// //   // Add a new product order to a shop
// //   Future<void> addProductOrder(String cityName, String shopName, ProductOrder order) async {
// //     try {
// //       await _db
// //           .collection('cities')
// //           .doc(cityName)
// //           .collection('shops')
// //           .doc(shopName)
// //           .collection('orders')
// //           .add(order.toMap());  // Save product order to Firestore
// //     } catch (e) {
// //       print('Error adding product order: $e');
// //     }
// //   }
// //
// //   // Get product orders from a shop
// //   Stream<List<ProductOrder>> getProductOrders(String cityName, String shopName) {
// //     return _db
// //         .collection('cities')
// //         .doc(cityName)
// //         .collection('shops')
// //         .doc(shopName)
// //         .collection('orders')
// //         .snapshots()
// //         .map((snapshot) {
// //       return snapshot.docs
// //           .map((doc) => ProductOrder.fromMap(doc.data() as Map<String, dynamic>))
// //           .toList();
// //     });
// //   }
// // }
//
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../model/order.dart'; // Ensure this import points to your ProductOrder model
//
// class FirestoreService {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//
//   /// Add a new product order to a shop
//   Future<void> addProductOrder(String cityName, String shopName, ProductOrder order) async {
//     try {
//       // Reference to the shop's orders collection
//       final orderRef = _db
//           .collection('cities')
//           .doc(cityName)
//           .collection('shops')
//           .doc(shopName)
//           .collection('orders')
//           .doc();
//
//       // Add the order with its generated ID
//       final orderWithId = order.copyWith(orderId: orderRef.id);
//       await orderRef.set(orderWithId.toMap());
//     } catch (e) {
//       print('Error adding product order: $e');
//       rethrow; // Optionally, rethrow for higher-level handling
//     }
//   }
//
//   /// Get product orders for a shop as a stream
//   Stream<List<ProductOrder>> getProductOrders(String cityName, String shopName) {
//     return _db
//         .collection('cities')
//         .doc(cityName)
//         .collection('shops')
//         .doc(shopName)
//         .collection('orders')
//         .snapshots()
//         .map((snapshot) {
//       return snapshot.docs.map((doc) {
//         final data = doc.data();
//         return ProductOrder(
//           orderId: doc.id,
//           productName: data['productName'] ?? 'Unknown Product',
//           status: data['status'] ?? 'Pending',
//           createdAt: (data['createdAt'] as Timestamp?)!.toDate(),
//           size: data['size'] ?? '',
//           dimensions: data['dimensions'] ?? '',
//           type: data['type'] ?? '',
//           imageUrl: data['imageUrl'] ?? '',
//           extraDetails: data['extraDetails'] ?? '',
//           orderDate: (data['orderDate'] as Timestamp?)!.toDate(),
//         );
//       }).toList();
//     });
//   }
//
//
//
//   /// Update an existing product order
//   Future<void> updateOrderStatus(String cityName, String shopName, String orderId, String newStatus) async {
//     try {
//       await _db
//           .collection('cities')
//           .doc(cityName)
//           .collection('shops')
//           .doc(shopName)
//           .collection('orders')
//           .doc(orderId)
//           .update({'status': newStatus});
//     } catch (e) {
//       print('Error updating order status: $e');
//       rethrow;
//     }
//   }
//
//   /// Delete a product order
//   Future<void> deleteProductOrder(String cityName, String shopName, String orderId) async {
//     try {
//       final orderRef = _db
//           .collection('cities')
//           .doc(cityName)
//           .collection('shops')
//           .doc(shopName)
//           .collection('orders')
//           .doc(orderId);
//
//       await orderRef.delete();
//     } catch (e) {
//       print('Error deleting product order: $e');
//       rethrow;
//     }
//   }
// }
