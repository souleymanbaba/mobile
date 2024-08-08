import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'product_list.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'cart_page.dart';
import 'orders_page.dart';
import 'package:e_commerce/WishlistPage.dart';
import 'language_provider.dart'; // Importer le fournisseur de langue

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp(
          title: 'Flutter Product App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: ProductList(),
          routes: {
            '/login': (context) => LoginPage(),
            '/signup': (context) => SignupPage(),
            '/cart': (context) => CartPage(),
            '/orders': (context) => OrdersPage(),
            '/wishlist': (context) => WishlistPage(),
          },
        );
      },
    );
  }
}
