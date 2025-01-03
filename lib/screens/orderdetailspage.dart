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

  List<String> _selectedSize = [];  // To store multiple selected sizes
  List<String> _selectedDimensions = [];  // To store multiple selected dimensions
  String _selectedType = '';
  DateTime _selectedDate = DateTime.now();

  bool _isSubmitting = false;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _productController.text = widget.order.productName;
    _extraDetailsController.text = widget.order.extraDetails;
    _selectedSize = widget.order.size != null ? widget.order.size!.split(', ') : []; // Convert string to list
    _selectedDimensions = widget.order.dimensions != null ? widget.order.dimensions!.split(', ') : []; // Convert string to list
    _selectedType = widget.order.type;
    _selectedDate = widget.order.orderDate;
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
          size: _selectedSize.join(', '),
          dimensions: _selectedDimensions.join(', '),
          type: _selectedType,
          imageUrl: imageUrl ?? widget.order.imageUrl,
          createdAt: widget.order.createdAt,
          extraDetails: _extraDetailsController.text,
          orderDate: _selectedDate,
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

  Widget _buildDropdown({
    required List<String> selectedValues,
    required Function(List<String>) onChanged,
    required List<String> items,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.black), // Label text color set to black
          filled: true,
          fillColor: Colors.teal.shade50,
          border: OutlineInputBorder(),
        ),
        child: Wrap(
          spacing: 8.0,
          children: items.map((item) {
            final isSelected = selectedValues.contains(item);
            return ChoiceChip(
              label: Text(
                item,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black, // Set text color based on selection
                ),
              ),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    selectedValues.add(item);
                  } else {
                    selectedValues.remove(item);
                  }
                });
                onChanged(selectedValues);
              },
              selectedColor: Colors.teal, // Background color for selected chips
              backgroundColor: Colors.grey.shade200, // Background color for unselected chips
            );
          }).toList(),
        ),
      ),
    );


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


            // Size Dropdown
            _buildDropdown(
              selectedValues: _selectedSize,
              onChanged: (List<String> value) {
                setState(() {
                  _selectedSize = value;
                });
              },
              items: ['2 yr mattress', '5 yr mattress', '10 yr mattress', 'R1 model', 'R2 model', 'c1 model', 'c2 model', 's1 model', 's2 model', 'a1 model', 'a2 model', 'f5 model', 'f1 model', 'Custom'],
              label: 'Model Size',


            ),

            if (_selectedSize.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Wrap(
                  spacing: 8.0,
                  children: _selectedSize.map((size) {
                    return Chip(
                      label: Text(size),
                      onDeleted: () {
                        setState(() {
                          _selectedSize.remove(size);
                        });
                      },
                    );
                  }).toList(),
                ),
              ),


            if (_selectedSize.contains('Custom'))
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: TextField(
                    controller: _customDimensionsController,
                    decoration: InputDecoration(
                      labelText: 'Enter Custom Dimensions',
                      labelStyle: TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.teal.shade50,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
              ),

            // Dimensions Dropdown
            _buildDropdown(
              selectedValues: _selectedDimensions,
              onChanged: (List<String> value) {
                setState(() {
                  _selectedDimensions = value;
                });
              },
              items: ['5x6', '9x5', '10x10', 'Custom'],
              label: 'Selected Dimensions',
            ),

            if (_selectedDimensions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Wrap(
                  spacing: 8.0,
                  children: _selectedDimensions.map((dimension) {
                    return Chip(
                      label: Text(dimension),
                      onDeleted: () {
                        setState(() {
                          _selectedDimensions.remove(dimension);
                        });
                      },
                    );
                  }).toList(),
                ),
              ),



            // Custom Dimensions Field (only if Custom is selected)
            if (_selectedDimensions.contains('Custom'))
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: TextField(
                    controller: _customDimensionsController,
                    decoration: InputDecoration(
                      labelText: 'Enter Custom Dimensions',
                      labelStyle: TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.teal.shade50,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
              ),

            // Type Dropdown
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  value: _selectedType,
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
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
              ),
            ),


            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: TextField(
                  controller: _productController,
                  decoration: InputDecoration(
                    labelText: 'No. Of Pieces',
                    labelStyle: TextStyle(
                        color: Colors.teal, fontWeight: FontWeight.bold),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.teal.shade50,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
            ),
            // Extra Details Field
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: TextField(
                  controller: _extraDetailsController,
                  decoration: InputDecoration(
                    labelText: 'Additional Details',
                    labelStyle: TextStyle(
                        color: Colors.teal, fontWeight: FontWeight.bold),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.teal.shade50,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
            ),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Order Created: ${widget.order.createdAt.toLocal().toString().split(' ')[0]}',
                  style: TextStyle(fontSize: 16, color: Colors.teal),
                ),
              ),
            ),

            // Image Picker Button
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.camera_alt,color: Colors.white,),
                  label: Text('Pick Image',style: TextStyle(color: Colors.white),),
                  onPressed: _pickImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),

            // Update Button
            ElevatedButton(
              onPressed: _updateOrder,
              child: Text('Update Order',style: TextStyle(color: Colors.white),),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 14.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}