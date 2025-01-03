import 'dart:io';
import 'package:factory1/screens/completeorder.dart';
import 'package:factory1/screens/orderdetailspage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../model/order.dart';
import 'package:multiselect/multiselect.dart';  // Import multi_select package


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
  List<String> _selectedSize = [];  // To store multiple selected sizes
  List<String> _selectedDimensions = [];  // To store multiple selected dimensions
  String _selectedType = 'Type 1';
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;


  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<String> _modelNames = [
    '2 Yr Mattress',
    '5 Yr Mattress',
    '10 Yr Mattress',
    'R1 Model',
    'R2 Model',
    'C1 Model',
    'C2 Model',
    'S1 Model',
    'S2 Model',
    'A1 Model',
    'A2 Model',
    'F5 Model',
    'F1 Model',
  ];

  final List<String> _dimensions = ['5x6', '9x5', '10x10'];

  Future<void> addProductOrder(String cityName, String shopName, ProductOrder order) async {
    try {
      final orderRef = _db
          .collection('cities')
          .doc(cityName)
          .collection('shops')
          .doc(shopName)
          .collection('orders')
          .doc(); // Auto-generate a unique ID

      final updatedOrder = order.copyWith(orderId: orderRef.id); // Include generated ID
      await orderRef.set(updatedOrder.toMap()); // Write updated order with ID
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
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.teal[900]!, // Date text color
            ),
            dialogBackgroundColor: Colors.teal[50], // Background of the dialog
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.teal, // Button text color
              ),
            ),
          ),
          child: Builder(
            builder: (BuildContext context) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: child!,
              );
            },
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }


  Future<String?> _showCustomTextInputDialog(BuildContext context, String title) async {
    final TextEditingController _customTextController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: _customTextController,
            decoration: InputDecoration(hintText: 'Enter custom text'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_customTextController.text);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
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

        final order = ProductOrder(
          productName: _productController.text,
          size: _selectedSize.join(', '),
          dimensions: _selectedDimensions.join(', '),
          type: _selectedType,
          imageUrl: imageUrl,
          createdAt: _selectedDate,
          extraDetails: _extraDetailsController.text,
          orderDate: DateTime.now(),
          status: 'Pending',
          cityName: widget.cityName,
          shopName: widget.shopName,
          orderId: '',
        );

        await addProductOrder(widget.cityName, widget.shopName, order);

        setState(() {
          _productController.clear();
          _extraDetailsController.clear();
          _customDimensionsController.clear();
          _imageFile = null;
          _selectedSize = [];
          _selectedDimensions = [];
          _selectedType = 'Type 1';
          _selectedDate = DateTime.now();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order submitted successfully!')),
        );

        // Force refresh UI
        setState(() {});
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
    children: <Widget>[
      // Product Name Input
      // Size Dropdown

      Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Model Names:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 4.0,
              runSpacing: 2.0,
              children: _modelNames.map((model) {
                final isSelected = _selectedSize.contains(model);
                return ChoiceChip(
                  label: Text(model),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedSize.add(model);
                      } else {
                        _selectedSize.remove(model);
                      }
                    });
                  },
                  selectedColor: Colors.teal.shade200,
                  backgroundColor: Colors.teal.shade50,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
            ElevatedButton(
              onPressed: () async {
                String? customText = await _showCustomTextInputDialog(context, 'Add Custom Model Name');
                if (customText != null && customText.isNotEmpty) {
                  setState(() {
                    _modelNames.add(customText);
                    _selectedSize.add(customText);
                  });
                }
              },
              child: Text('Custom'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    ),

        // Selected Model Display
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Selected Model: ', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Expanded(
                  child: Wrap(
                    spacing: 2.0,
                    runSpacing: -5.0,
                    children: _selectedSize.map((model) {
                      return Chip(
                        label: Text(model),
                        backgroundColor: Colors.teal,
                        labelStyle: TextStyle(color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Select Dimensions
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Dimensions:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 4.0,
                  runSpacing: 2.0,
                  children: _dimensions.map((dimension) {
                    final isSelected = _selectedDimensions.contains(dimension);
                    return ChoiceChip(
                      label: Text(dimension),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedDimensions.add(dimension);
                          } else {
                            _selectedDimensions.remove(dimension);
                          }
                        });
                      },
                      selectedColor: Colors.teal.shade200,
                      backgroundColor: Colors.teal.shade50,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList(),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String? customText = await _showCustomTextInputDialog(context, 'Add Custom Dimensions');
                    if (customText != null && customText.isNotEmpty) {
                      setState(() {
                        _dimensions.add(customText);
                        _selectedDimensions.add(customText);
                      });
                    }
                  },
                  child: Text('Custom'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Selected Dimensions Display
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Selected Dimensions: ', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Expanded(
                  child: Wrap(
                    spacing: 2.0,
                    runSpacing: -5.0,
                    children: _selectedDimensions.map((dimension) {
                      return Chip(
                        label: Text(dimension),
                        backgroundColor: Colors.teal,
                        labelStyle: TextStyle(color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),

        // No. of Pieces Input
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _productController,
              decoration: InputDecoration(
                labelText: 'No. of Pieces',
                labelStyle: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.teal.shade50,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
        ),

        // Product Type Dropdown
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                labelText: 'Select Type',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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

        // Extra Details Input
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _extraDetailsController,
              decoration: InputDecoration(
                labelText: 'Additional Details',
                labelStyle: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.teal.shade50,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
        ),

        // Image Picker
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: _imageFile == null
                ? ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.image, color: Colors.white),
              label: Text('Pick an Image', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          ),
        ),


        // Submit Button
      Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
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
        ),
      ),

// Submit Button
      Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _submitOrder,
            icon: Icon(Icons.shopping_cart_checkout, color: Colors.white),
            label: Text(
              'Submit Order',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),

      SizedBox(height: 24),

// Order List
      StreamBuilder<List<ProductOrder>>(
        stream: getProductOrders(widget.cityName, widget.shopName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            print('Waiting for data...');
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
