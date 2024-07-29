import 'package:flutter/material.dart';
import 'cart_service.dart';
import 'storage_service.dart';
import 'dart:convert'; // Import needed for base64 decoding

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool loading = true;
  Map<String, dynamic>? cart;
  int? userId;
  String? selectedWilaya;
  String? selectedMoughataa;
  TextEditingController phoneController = TextEditingController();

  final List<Map<String, dynamic>> wilayas = [
    {
      'name': 'Nouakchott-Nord',
      'moughataas': ['Teyarett', 'Dar Naim', 'Toujounine']
    },
    {
      'name': 'Nouakchott-Ouest',
      'moughataas': ['Tevragh-Zeina', 'Ksar', 'Sébkha']
    },
    {
      'name': 'Nouakchott-Sud',
      'moughataas': ['Arafat', 'El Mina', 'Riyad']
    }
  ];

  @override
  void initState() {
    super.initState();
    _fetchCartData();
  }

  Future<void> _fetchCartData() async {
    final userId = await StorageService().getUserIdd();
    setState(() {
      this.userId = userId;
    });
    if (userId != null) {
      try {
        final data = await CartService().fetchCartData(userId);
        setState(() {
          cart = data;
          loading = false;
        });
      } catch (error) {
        setState(() {
          loading = false;
        });
        print('Error fetching cart data: $error');
      }
    } else {
      setState(() {
        loading = false;
      });
      print('User ID is null');
    }
  }

  Future<void> _updateQuantity(int productId, String endpoint) async {
    try {
      final userId = await StorageService().getUserIdd();
      setState(() {
        this.userId = userId;
      });
      await CartService().updateQuantity(userId!, productId, endpoint);
      _fetchCartData();
    } catch (error) {
      print('Error updating quantity: $error');
    }
  }

  Future<void> _removeCartItem(int cartItemId) async {
    try {
      await CartService().removeCartItem(cartItemId);
      _fetchCartData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Produit a ete supprime de la cart !')),
      );
    } catch (error) {
      print('Error removing item: $error');
    }
  }

  Future<void> _placeOrder(Map<String, dynamic> orderData) async {
    try {
      await CartService().placeOrder(orderData);
      setState(() {
        cart = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order placed successfully')));
    } catch (error) {
      print('Error placing order: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to place order. Please try again.')));
    }
  }

  void _showOrderDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Place Order'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(labelText: 'Phone Number'),
                    ),
                    DropdownButton<String>(
                      hint: Text('Select Wilaya'),
                      value: selectedWilaya,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedWilaya = newValue;
                          selectedMoughataa = null; // Reset the moughataa when wilaya changes
                        });
                      },
                      items: wilayas.map<DropdownMenuItem<String>>((Map<String, dynamic> wilaya) {
                        return DropdownMenuItem<String>(
                          value: wilaya['name'],
                          child: Text(wilaya['name']),
                        );
                      }).toList(),
                    ),
                    if (selectedWilaya != null)
                      DropdownButton<String>(
                        hint: Text('Select Moughataa'),
                        value: selectedMoughataa,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedMoughataa = newValue;
                          });
                        },
                        items: wilayas
                            .firstWhere((wilaya) => wilaya['name'] == selectedWilaya)['moughataas']
                            .map<DropdownMenuItem<String>>((String moughataa) {
                          return DropdownMenuItem<String>(
                            value: moughataa,
                            child: Text(moughataa),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedWilaya != null && selectedMoughataa != null && phoneController.text.isNotEmpty) {
                      _placeOrder({
                        'userId': userId!,
                        'address': phoneController.text,
                        'orderDescription': 'Sample Order',
                        'wilaya': selectedMoughataa,
                        'latitude': null,
                        'longitude': null
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('La commande a été passée avec succès')));
                      Navigator.of(context).pop();

                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please fill in all the fields')));
                    }
                  },
                  child: Text('Place Order'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Cart')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (cart == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Cart')),
        body: Center(child: Text('Your cart is empty.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Cart')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: cart!['cartItems'].length,
              itemBuilder: (context, index) {
                final item = cart!['cartItems'][index];
                return ListTile(
                  leading: item['returnedImg'] != null
                      ? Image.memory(base64Decode(item['returnedImg']))
                      : Icon(Icons.image_not_supported),
                  title: Text(item['marque']),
                  subtitle: Text('Price: ${item['price']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () {
                          if (item['quantity'] == 1) {
                            _removeCartItem(item['id']);
                          } else {
                            _updateQuantity(item['productId'], 'deduction');
                          }
                        },
                      ),
                      Text('${item['quantity']}'),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () => _updateQuantity(item['productId'], 'addition'),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _removeCartItem(item['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Column(
                children: [
                  Text('Total Price: ${cart!['totalAmount']}'),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _showOrderDialog,
                    child: Text('Place Order'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


