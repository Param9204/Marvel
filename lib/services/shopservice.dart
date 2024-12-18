import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add a new city to Firestore
  Future<void> addCity(String cityName) async {
    try {
      await _db.collection('cities').add({
        'name': cityName,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding city: $e');
    }
  }

  // Get cities from Firestore
  Stream<List<Map<String, dynamic>>> getCities() {
    return _db.collection('cities').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    });
  }

  // Add a shop under a specific city
  Future<void> addShop(String cityName, String shopName) async {
    try {
      // Create a new document under the 'shops' collection for the city
      await _db.collection('cities').doc(cityName).collection('shops').add({
        'name': shopName,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding shop: $e');
    }
  }

  // Get shops under a specific city
  Stream<List<Map<String, dynamic>>> getShops(String cityName) {
    return _db
        .collection('cities')
        .doc(cityName)
        .collection('shops')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id, // Document ID (can be used for deletion)
          'name': doc['name'], // Shop name from the 'name' field
        };
      }).toList();
    });
  }

  // Delete a shop from a city
  Future<void> deleteShop(String cityName, String shopId) async {
    try {
      await _db
          .collection('cities')
          .doc(cityName)
          .collection('shops')
          .doc(shopId)
          .delete();
    } catch (e) {
      print('Error deleting shop: $e');
    }
  }
}
