import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../model/order.dart'; // Ensure this import is added

class CompletedOrdersPage extends StatefulWidget {
  final String cityName;
  final String shopName;

  const CompletedOrdersPage({required this.cityName, required this.shopName});

  @override
  _CompletedOrdersPageState createState() => _CompletedOrdersPageState();
}

class _CompletedOrdersPageState extends State<CompletedOrdersPage> {
  String? selectedMonth;
  String? selectedYear;
  String? sortOption = 'Newest';
  Set<String> selectedOrders = {};

  // Function to get completed orders with sorting and filtering
  Stream<List<ProductOrder>> getCompletedOrders() {
    Query query = FirebaseFirestore.instance
        .collection('cities')
        .doc(widget.cityName)
        .collection('shops')
        .doc(widget.shopName)
        .collection('orders')
        .where('status', isEqualTo: 'Completed');

    if (selectedMonth != null && selectedYear != null) {
      final startDate = DateTime(
        int.parse(selectedYear!),
        int.parse(selectedMonth!),
      );
      final endDate = DateTime(
        int.parse(selectedYear!),
        int.parse(selectedMonth!) + 1,
      );

      query = query
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThan: endDate);
    }

    if (sortOption == 'Newest') {
      query = query.orderBy('createdAt', descending: true);
    } else if (sortOption == 'Oldest') {
      query = query.orderBy('createdAt', descending: false);
    } else if (sortOption == 'ProductName') {
      query = query.orderBy('productName');
    }

    return query.snapshots().map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['orderId'] = doc.id;
      return ProductOrder.fromMap(data);
    }).toList());
  }

  void showOrderDetailsDialog(BuildContext context, ProductOrder order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Order Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  order.imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
                SizedBox(height: 8),
                Text('Product Name: ${order.productName}'),
                SizedBox(height: 8),
                Text('Size: ${order.size}'),
                SizedBox(height: 8),
                Text('Dimensions: ${order.dimensions}'),
                SizedBox(height: 8),
                Text('Type: ${order.type}'),
                SizedBox(height: 8),
                Text('Extra Details: ${order.extraDetails}'),
                SizedBox(height: 8),
                Text('Completed on: ${order.orderDate}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('cities')
                    .doc(order.cityName)
                    .collection('shops')
                    .doc(order.shopName)
                    .collection('orders')
                    .doc(order.orderId)
                    .delete();
                Navigator.of(context).pop();
              },
              child: Text('Delete Order', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget buildAnalyticsCard(List<ProductOrder> orders) {
    final Map<String, int> dimensionsCount = {};
    final Map<String, int> sizeCount = {};

    for (var order in orders) {
      dimensionsCount[order.dimensions] = (dimensionsCount[order.dimensions] ?? 0) + 1;
      sizeCount[order.size] = (sizeCount[order.size] ?? 0) + 1;
    }

    final totalOrders = orders.length;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text('Total Orders: $totalOrders'),
          SizedBox(height: 8),
          Text('Orders by Dimensions: ${dimensionsCount.entries.map((e) => "${e.key} (${e.value})").join(', ')}'),
          Text('Orders by Size: ${sizeCount.entries.map((e) => "${e.key} (${e.value})").join(', ')}'),
          Divider(height: 20, thickness: 1),
          Text(
            'Orders by Dimensions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          Container(
            height: 100, // Smaller chart size
            child: PieChart(
              PieChartData(
                sections: dimensionsCount.entries
                    .map((entry) => PieChartSectionData(
                  value: entry.value.toDouble(),
                  title: entry.key,
                  color: Colors.primaries[dimensionsCount.keys.toList().indexOf(entry.key) % Colors.primaries.length],
                ))
                    .toList(),
              ),
            ),
          ),
          Divider(height: 20, thickness: 1),
          Text(
            'Orders by Size',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          Container(
            height: 100, // Smaller chart size
            child: PieChart(
              PieChartData(
                sections: sizeCount.entries
                    .map((entry) => PieChartSectionData(
                  value: entry.value.toDouble(),
                  title: entry.key,
                  color: Colors.accents[sizeCount.keys.toList().indexOf(entry.key) % Colors.accents.length],
                ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.greenAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text('Completed Orders'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            tooltip: 'Filter Orders',
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Filter Orders'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedMonth,
                          onChanged: (value) {
                            setState(() {
                              selectedMonth = value;
                            });
                          },
                          decoration: InputDecoration(labelText: 'Select Month'),
                          items: List.generate(12, (index) {
                            final month = index + 1;
                            return DropdownMenuItem(
                              value: month.toString().padLeft(2, '0'),
                              child: Text(DateTime(0, month).month.toString()),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedYear,
                          onChanged: (value) {
                            setState(() {
                              selectedYear = value;
                            });
                          },
                          decoration: InputDecoration(labelText: 'Select Year'),
                          items: List.generate(10, (index) {
                            final year = DateTime.now().year - index;
                            return DropdownMenuItem(
                              value: year.toString(),
                              child: Text(year.toString()),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Apply'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedMonth = null;
                            selectedYear = null;
                          });
                          Navigator.of(context).pop();
                        },
                        child: Text('Clear'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ProductOrder>>(
        stream: getCompletedOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No completed orders found.'));
          } else {
            final orders = snapshot.data!;
            return Column(
              children: [
                buildAnalyticsCard(orders),
                Expanded(
                  child: ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Checkbox(
                            value: selectedOrders.contains(order.orderId),
                            onChanged: (isSelected) {
                              setState(() {
                                if (isSelected!) {
                                  selectedOrders.add(order.orderId);
                                } else {
                                  selectedOrders.remove(order.orderId);
                                }
                              });
                            },
                          ),
                          title: Text(order.productName),
                          subtitle: Text('Completed on: ${order.orderDate}'),
                          trailing: Image.network(order.imageUrl, width: 50, height: 50),
                          onTap: () {
                            showOrderDetailsDialog(context, order);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Bulk action logic (e.g., delete selected orders)
          selectedOrders.forEach((orderId) async {
            await FirebaseFirestore.instance
                .collection('cities')
                .doc(widget.cityName)
                .collection('shops')
                .doc(widget.shopName)
                .collection('orders')
                .doc(orderId)
                .delete();
          });

          setState(() {
            selectedOrders.clear();
          });

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected orders deleted successfully!')));
        },
        child: Icon(Icons.delete),
        backgroundColor: Colors.red,
      ),
    );
  }
}
