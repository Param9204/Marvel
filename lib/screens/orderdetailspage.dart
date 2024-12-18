import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../model/order.dart'; // Make sure this path is correct.

class OrderDetailsPage extends StatefulWidget {
  final ProductOrder order;
  final String cityName;
  final String shopName;

  const OrderDetailsPage({
    required this.order,
    required this.cityName,
    required this.shopName,
  });

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _extraDetailsController = TextEditingController();
  final TextEditingController _customDimensionsController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;

  String _selectedSize = '';
  String _selectedDimensions = '';
  String _selectedType = '';
  DateTime _selectedDate = DateTime.now();

  bool _isSubmitting = false;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _productController.text = widget.order.productName;
    _extraDetailsController.text = widget.order.extraDetails;
    _selectedSize = widget.order.size;
    _selectedDimensions = widget.order.dimensions;
    _selectedType = widget.order.type;
    _selectedDate = widget.order.orderDate; // Initialize date from order
  }

  // Method to pick an image from the gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  // Method to select a new date
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Method to update the order
  Future<void> _updateOrder() async {
    if (_productController.text.isNotEmpty) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final orderRef = _db
            .collection('cities')
            .doc(widget.cityName)
            .collection('shops')
            .doc(widget.shopName)
            .collection('orders')
            .doc(widget.order.orderId);

        final docSnapshot = await orderRef.get();
        if (!docSnapshot.exists) {
          throw Exception('Order not found!');
        }

        String? imageUrl = widget.order.imageUrl;

        // If a new image is selected, upload it to Firebase Storage
        if (_imageFile != null) {
          final ref = FirebaseStorage.instance
              .ref()
              .child('products/${DateTime.now().millisecondsSinceEpoch}');
          await ref.putFile(File(_imageFile!.path));
          imageUrl = await ref.getDownloadURL();
        }

        // Create an updated order with the new values
        final updatedOrder = ProductOrder(
          productName: _productController.text,
          size: _selectedSize,
          dimensions: _selectedDimensions == 'Custom'
              ? _customDimensionsController.text
              : _selectedDimensions,
          type: _selectedType,
          imageUrl: imageUrl ?? widget.order.imageUrl,
          createdAt: widget.order.createdAt,
          extraDetails: _extraDetailsController.text,
          orderDate: _selectedDate, // Use the updated date
          status: widget.order.status,
          cityName: widget.cityName,
          shopName: widget.shopName,
          orderId: widget.order.orderId,
        );

        // Update the order in Firestore
        await orderRef.update(updatedOrder.toMap());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order updated successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating order: $e')),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields.')),
      );
    }
  }

  // Method to delete the order
  Future<void> _deleteOrder() async {
    try {
      final orderRef = _db
          .collection('cities')
          .doc(widget.cityName)
          .collection('shops')
          .doc(widget.shopName)
          .collection('orders')
          .doc(widget.order.orderId);

      // Delete the order document from Firestore
      await orderRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order deleted successfully!')),
      );

      Navigator.pop(context); // Navigate back after deletion
    } catch (e) {
      print("Error deleting order: $e"); // Log the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'),
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
            icon: Icon(Icons.delete),
            onPressed: _deleteOrder,
          ),
        ],
      ),
      body: _isSubmitting
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Product Name Field
            _buildInputField(
              controller: _productController,
              label: 'Product Name',
            ),

            // Size Dropdown
            _buildDropdown(
              value: _selectedSize,
              onChanged: (value) {
                setState(() {
                  _selectedSize = value!;
                });
              },
              items: ['Small', 'Medium', 'Large'],
              label: 'Size',
            ),

            // Dimensions Dropdown
            _buildDropdown(
              value: _selectedDimensions,
              onChanged: (value) {
                setState(() {
                  _selectedDimensions = value!;
                });
              },
              items: ['5x6', '9x5', '10x10', 'Custom'],
              label: 'Dimensions',
            ),
            if (_selectedDimensions == 'Custom')
              _buildInputField(
                controller: _customDimensionsController,
                label: 'Enter Custom Dimensions',
              ),

            // Type Dropdown
            _buildDropdown(
              value: _selectedType,
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
              items: ['Type 1', 'Type 2', 'Type 3'],
              label: 'Type',
            ),

            // Extra Details Field
            _buildInputField(
              controller: _extraDetailsController,
              label: 'Extra Details (Optional)',
            ),

            // Order Date Display and Update
            Row(
              children: [
                Text('Order Date: ${_selectedDate.toLocal().toIso8601String()}'),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: _selectDate,
                ),
              ],
            ),
            SizedBox(height: 16),

            // Display Image
            _imageFile == null
                ? Image.network(widget.order.imageUrl)
                : Image.file(File(_imageFile!.path)),
            SizedBox(height: 16),

            // Pick Image Button
            _buildButton(
              label: 'Pick a New Image',
              onPressed: _pickImage,
            ),
            SizedBox(height: 16),

            // Update Order Button
            _buildButton(
              label: 'Update Order',
              onPressed: _updateOrder,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          filled: true,
          fillColor: Colors.teal.shade50,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required Function(String?) onChanged,
    required List<String> items,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.teal.shade50,
          border: OutlineInputBorder(),
        ),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
    Color color = Colors.blue,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 14.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }
}
