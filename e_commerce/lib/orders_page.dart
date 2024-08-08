import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'storage_service.dart';
import 'language_provider.dart'; // Importer le fournisseur de langue
import 'traduction.dart'; // Importer le fichier de traductions
import 'package:provider/provider.dart';

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  bool loading = true;
  List<dynamic> orders = [];
  int? userId;
  List<dynamic> cartItems = [];
  int currentPage = 1;
  int ordersPerPage = 5;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final userId = await StorageService().getUserIdd();
    setState(() {
      this.userId = userId;
    });
    if (userId != null) {
      try {
        final response = await http.get(Uri.parse('http://192.168.100.165:8080/api/customer/myOrders/$userId'));
        setState(() {
          orders = jsonDecode(response.body);
          loading = false;
        });
      } catch (error) {
        setState(() {
          loading = false;
        });
        print('Error fetching orders: $error');
      }
    } else {
      setState(() {
        loading = false;
      });
      print('User ID is null');
    }
  }

  Future<void> _fetchCartItems(int userId, int orderId) async {
    try {
      final uri = Uri.http(
          '192.168.100.165:8080',
          '/api/customer/cartI/$userId',
          {'orderId': orderId.toString()}
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('cartItems')) {
          setState(() {
            cartItems = data['cartItems'] ?? [];
          });
          _showCartModal();
        } else {
          throw Exception('Invalid data format');
        }
      } else {
        throw Exception('Failed to load cart items');
      }
    } catch (error) {
      print('Error fetching cart items: $error');
    }
  }

  void _showCartModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        String selectedLanguage = Provider.of<LanguageProvider>(context).selectedLanguage;
        return Directionality(
          textDirection: selectedLanguage == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                Text(translate('cart_items', selectedLanguage), style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      final imageBytes = base64Decode(item['returnedImg']);
                      return ListTile(
                        title: Text(item['productNane'] ?? 'N/A'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${translate('quantity', selectedLanguage)}: ${item['quantity'] ?? 'N/A'}'),
                            if (item['returnedImg'] != null)
                              Container(
                                width: 100,
                                height: 100,
                                child: Image.memory(imageBytes, fit: BoxFit.cover),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _paginate(int pageNumber) {
    setState(() {
      currentPage = pageNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    String selectedLanguage = Provider.of<LanguageProvider>(context).selectedLanguage;
    TextDirection textDirection = (selectedLanguage == 'ar') ? TextDirection.rtl : TextDirection.ltr;

    if (loading) {
      return Directionality(
        textDirection: textDirection,
        child: Scaffold(
          appBar: AppBar(title: Text(translate('orders', selectedLanguage))),
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (orders.isEmpty) {
      return Directionality(
        textDirection: textDirection,
        child: Scaffold(
          appBar: AppBar(title: Text(translate('orders', selectedLanguage))),
          body: Center(child: Text(translate('no_orders', selectedLanguage))),
        ),
      );
    }

    int indexOfLastOrder = currentPage * ordersPerPage;
    int indexOfFirstOrder = indexOfLastOrder - ordersPerPage;
    List<dynamic> currentOrders = orders.sublist(
      indexOfFirstOrder,
      indexOfLastOrder > orders.length ? orders.length : indexOfLastOrder,
    );

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        appBar: AppBar(title: Text(translate('orders', selectedLanguage))),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Table(
                border: TableBorder.all(),
                children: [
                  TableRow(
                    children: [
                      TableCell(child: Text(translate('amount', selectedLanguage), style: TextStyle(fontWeight: FontWeight.bold))),
                      TableCell(child: Text(translate('number', selectedLanguage), style: TextStyle(fontWeight: FontWeight.bold))),
                      TableCell(child: Text(translate('date', selectedLanguage), style: TextStyle(fontWeight: FontWeight.bold))),
                      TableCell(child: Text(translate('status', selectedLanguage), style: TextStyle(fontWeight: FontWeight.bold))),
                      TableCell(child: Text(translate('actions', selectedLanguage), style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                  for (var order in currentOrders)
                    TableRow(
                      children: [
                        TableCell(child: Text(order['amount'].toString())),
                        TableCell(child: Text(order['address'] ?? 'N/A')),
                        TableCell(child: Text(order['date'] ?? 'N/A')),
                        TableCell(child: Text(order['orderStatus'] ?? 'N/A')),
                        TableCell(
                          child: IconButton(
                            icon: Icon(Icons.shopping_cart),
                            onPressed: () => _fetchCartItems(userId!, order['id']),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              Pagination(
                currentPage: currentPage,
                totalPages: (orders.length / ordersPerPage).ceil(),
                onPageChanged: _paginate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Pagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;

  Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        return GestureDetector(
          onTap: () => onPageChanged(index + 1),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 5),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: currentPage == index + 1 ? Colors.blue : Colors.grey,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              (index + 1).toString(),
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }),
    );
  }
}
