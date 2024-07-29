import 'package:flutter/material.dart';
import 'product_list.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'cart_page.dart';
import 'orders_page.dart'; // Ajoutez cette ligne
import 'package:e_commerce/WishlistPage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Product App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ProductList(),
      routes: {
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/cart': (context) => CartPage(),
        '/orders': (context) => OrdersPage(), // Ajoutez cette ligne
        '/wishlist': (context) => WishlistPage(),
      },
    );
  }
}
