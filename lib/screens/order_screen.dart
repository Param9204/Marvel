import 'dart:io';
import 'package:factory1/screens/completeorder.dart';
import 'package:factory1/screens/orderdetailspage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../model/order.dart';

class OrderFormPage extends StatefulWidget {
  final String shopName;
  final String cityName;

  const OrderFormPage({required this.shopName, required this.cityName});

  @override
  _OrderFormPageState createState() => _OrderFormPageState();
}

class _OrderFormPageState extends State<OrderFormPage> {
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _extraDetailsController = TextEditingController();
  final TextEditingController _customDimensionsController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  String _selectedSize = 'Small';
  String _selectedDimensions = '5x6';
  String _selectedType = 'Type 1';
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addProductOrder(String cityName, String shopName, ProductOrder order) async {
    try {
      final orderRef = _db
          .collection('cities')
          .doc(cityName)
          .collection('shops')
          .doc(shopName)
          .collection('orders')
          .doc();

      final updatedOrder = order.copyWith(orderId: orderRef.id);
      await orderRef.set(order.toMap());
    } catch (e) {
      print('Error adding product order: $e');
    }
  }

  Stream<List<ProductOrder>> getProductOrders(String cityName, String shopName) {
    return _db
        .collection('cities')
        .doc(cityName)
        .collection('shops')
        .doc(shopName)
        .collection('orders')
        .where('status', isEqualTo: 'Pending') // Only fetch pending orders
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['orderId'] = doc.id;
      return ProductOrder.fromMap(data);
    }).toList());
  }


  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitOrder() async {
    if (_imageFile != null && _productController.text.isNotEmpty) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('products/${DateTime.now().millisecondsSinceEpoch}');
        await ref.putFile(File(_imageFile!.path));
        final imageUrl = await ref.getDownloadURL();

        final orderRef = FirebaseFirestore.instance
            .collection('cities')
            .doc(widget.cityName)
            .collection('shops')
            .doc(widget.shopName)
            .collection('orders')
            .doc();

        final order = ProductOrder(
          productName: _productController.text,
          size: _selectedSize,
          dimensions: _selectedDimensions == 'Custom'
              ? _customDimensionsController.text
              : _selectedDimensions,
          type: _selectedType,
          imageUrl: imageUrl,
          createdAt: _selectedDate,
          extraDetails: _extraDetailsController.text,
          orderDate: DateTime.now(),
          status: 'Pending',
          cityName: widget.cityName,
          shopName: widget.shopName,
          orderId: orderRef.id,
        );

        await addProductOrder(widget.cityName, widget.shopName, order);

        setState(() {
          _productController.clear();
          _extraDetailsController.clear();
          _customDimensionsController.clear();
          _imageFile = null;
          _selectedSize = 'Small';
          _selectedDimensions = '5x6';
          _selectedType = 'Type 1';
          _selectedDate = DateTime.now();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order submitted successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting order: $e')),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields and upload an image.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order Form - ${widget.shopName}',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.greenAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.view_list, color: Colors.white), // Use an icon for better appearance
            tooltip: 'View Completed Orders', // Optional tooltip for accessibility
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CompletedOrdersPage(
                    cityName: widget.cityName,
                    shopName: widget.shopName,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      body: _isSubmitting
            ? Center(child: CircularProgressIndicator())
            : Padding(
        padding: const EdgeInsets.all(16.0),
    child: ListView(
    children: [
      // Product Name Input
      TextField(
        controller: _productController,
        decoration: InputDecoration(
          labelText: 'Product Name',
          labelStyle: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.teal.shade50,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
      SizedBox(height: 16),

      // Size Dropdown
      DropdownButtonFormField<String>(
        value: _selectedSize,
        onChanged: (value) {
          setState(() {
            _selectedSize = value!;
          });
        },
        decoration: InputDecoration(
          labelText: 'Select Size',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.teal.shade50,
        ),
        items: ['Small', 'Medium', 'Large']
            .map((size) => DropdownMenuItem(
          value: size,
          child: Text(size),
        ))
            .toList(),
      ),
      SizedBox(height: 16),

      // Dimensions Dropdown
      DropdownButtonFormField<String>(
        value: _selectedDimensions,
        onChanged: (value) {
          setState(() {
            _selectedDimensions = value!;
          });
        },
        decoration: InputDecoration(
          labelText: 'Select Dimensions',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.teal.shade50,
        ),
        items: ['5x6', '9x5', '10x10', 'Custom']
            .map((dimension) => DropdownMenuItem(
          value: dimension,
          child: Text(dimension),
        ))
            .toList(),
      ),
      if (_selectedDimensions == 'Custom')
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: TextField(
            controller: _customDimensionsController,
            decoration: InputDecoration(
              labelText: 'Enter Custom Dimensions',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.teal.shade50,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
      SizedBox(height: 16),

      // Product Type Dropdown
      DropdownButtonFormField<String>(
        value: _selectedType,
        onChanged: (value) {
          setState(() {
            _selectedType = value!;
          });
        },
        decoration: InputDecoration(
          labelText: 'Select Type',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.teal.shade50,
        ),
        items: ['Type 1', 'Type 2', 'Type 3']
            .map((type) => DropdownMenuItem(
          value: type,
          child: Text(type),
        ))
            .toList(),
      ),
      SizedBox(height: 16),

      // Extra Details Input
      TextField(
        controller: _extraDetailsController,
        decoration: InputDecoration(
          labelText: 'Additional Details',
          labelStyle: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.teal.shade50,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
      SizedBox(height: 16),

      // Image Picker
      _imageFile == null
          ? ElevatedButton.icon(
        onPressed: _pickImage,
        icon: Icon(Icons.image, color: Colors.white),
        label: Text('Pick an Image',style: TextStyle(color: Colors.white),),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      )
          : Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(_imageFile!.path),
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ),
      SizedBox(height: 16),

      // Order Date Picker
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Order Date: ${DateFormat.yMd().format(_selectedDate)}',
            style: TextStyle(fontSize: 16),
          ),
          IconButton(
            icon: Icon(Icons.calendar_today, color: Colors.teal),
            onPressed: _selectDate,
          ),
        ],
      ),
      SizedBox(height: 16),

      // Submit Button
      ElevatedButton.icon(
        onPressed: _submitOrder,
        icon: Icon(Icons.shopping_cart_checkout, color: Colors.white), // Add your icon here
        label: Text(
          'Submit Order',
          style: TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      SizedBox(height: 24),

      // Order List
      StreamBuilder<List<ProductOrder>>(
        stream: getProductOrders(widget.cityName, widget.shopName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No orders found.'));
          } else {
            return Column(
              children: snapshot.data!.map((order) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: ListTile(
                    contentPadding: EdgeInsets.all(12),
                    title: Text(order.productName, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(' ${order.status}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButton<String>(
                          value: order.status,
                          onChanged: (newStatus) async {
                            if (newStatus != null) {
                              await FirebaseFirestore.instance
                                  .collection('cities')
                                  .doc(widget.cityName)
                                  .collection('shops')
                                  .doc(widget.shopName)
                                  .collection('orders')
                                  .doc(order.orderId)
                                  .update({'status': newStatus});
                            }
                          },
                          items: ['Pending', 'Completed']
                              .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                              .toList(),
                        ),
                        SizedBox(width: 8),
                        Image.network(order.imageUrl, width: 50, height: 50),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailsPage(
                            order: order,
                            cityName: widget.cityName,
                            shopName: widget.shopName,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            );
          }
        },
      ),
    ],
    ),
        ),
    );
  }
}
