import 'package:cloud_firestore/cloud_firestore.dart';

class ProductOrder {
  final String orderId; // Add orderId field
  final String productName;
  final String size;
  final String dimensions;
  final String type;
  final String imageUrl;
  final DateTime createdAt;
  final String extraDetails;
  final DateTime orderDate;
  final String status;
  late final String cityName;
  late final String shopName;

  // Constructor
  ProductOrder({
    required this.orderId, // Include orderId in the constructor
    required this.productName,
    required this.size,
    required this.dimensions,
    required this.type,
    required this.imageUrl,
    required this.createdAt,
    required this.extraDetails,
    required this.orderDate,
    required this.status,
    required this.cityName,
    required this.shopName,
  });

  // Method to create an instance from Firestore document
  factory ProductOrder.fromMap(Map<String, dynamic> map) {
    return ProductOrder(
      productName: map['productName'] ?? '', // Provide default value
      size: map['size'] ?? '',
      dimensions: map['dimensions'] ?? '',
      type: map['type'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(), // Handle String case
      extraDetails: map['extraDetails'] ?? '',
      orderDate: map['orderDate'] is Timestamp
          ? (map['orderDate'] as Timestamp).toDate()
          : DateTime.tryParse(map['orderDate'] ?? '') ?? DateTime.now(),
      status: map['status'] ?? 'Pending',
      cityName: map['cityName'] ?? '',
      shopName: map['shopName'] ?? '',
      orderId: map['orderId'] ?? '', // Avoid null value
    );
  }


  // Method to convert the instance to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'productName': productName,
      'size': size,
      'dimensions': dimensions,
      'type': type,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'extraDetails': extraDetails,
      'orderDate': orderDate,
      'status': status,
      'cityName': cityName,
      'shopName': shopName,
    };
  }

  // A helper method to clone an order with a new orderId
  ProductOrder copyWith({String? orderId}) {
    return ProductOrder(
      orderId: orderId ?? this.orderId,  // Ensure orderId is preserved or updated
      productName: productName,
      size: size,
      dimensions: dimensions,
      type: type,
      imageUrl: imageUrl,
      createdAt: createdAt,
      extraDetails: extraDetails,
      orderDate: orderDate,
      status: status,
      cityName: cityName,
      shopName: shopName,
    );
  }
}
