import 'package:flutter/material.dart';
import 'product_model.dart';
import 'product_service.dart';
import 'storage_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'product_model.dart';
import 'product_service.dart';
import 'storage_service.dart';

class WishlistPage extends StatefulWidget {
  @override
  _WishlistPageState createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  bool loading = true;
  List<Product> wishlist = [];
  int? userId;
  String? successMessage;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchWishlist();
  }

  Future<void> _fetchWishlist() async {
    final userId = await StorageService().getUserIdd();
    setState(() {
      this.userId = userId;
    });
    if (userId != null) {
      try {
        final data = await ProductService().fetchWishlist(userId);
        setState(() {
          wishlist = data;
          loading = false;
        });
      } catch (error) {
        setState(() {
          loading = false;
        });
        print('Error fetching wishlist: $error');
      }
    } else {
      setState(() {
        loading = false;
      });
      print('User ID is null');
    }
  }

  Future<void> _removeFromWishlist(int? productId) async {
    if (productId == null) return;
    try {
      print("------------------------------------------------------------------------------------------------------------------");

      print(productId);
      print("------------------------------------------------------------------------------------------------------------------");
      await ProductService().removeFromWishlist(productId);
      setState(() {
        wishlist.removeWhere((item) => item.productId == productId);
        successMessage = 'Produit retiré de la wishlist';
        errorMessage = null;
      });
    } catch (error) {
      setState(() {
        successMessage = null;
        errorMessage = 'Erreur lors de la suppression du produit';
      });
      print('Error removing item from wishlist: $error');
    }
  }

  Future<void> _addToCart(int? productId) async {
    if (productId == null || userId == null) return;
    try {
      print(userId);
      await ProductService().addToCart(userId!, productId);
      setState(() {
        successMessage = 'Produit ajouté au panier';
        errorMessage = null;
      });
    } catch (error) {
      setState(() {
        successMessage = null;
        errorMessage = 'Erreur lors de l\'ajout du produit au panier';
      });
      print('Error adding item to cart: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Wishlist')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (wishlist.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Wishlist')),
        body: Center(child: Text('Votre wishlist est vide.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Wishlist')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (successMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  successMessage!,
                  style: TextStyle(color: Colors.green),
                ),
              ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: wishlist.length,
              itemBuilder: (context, index) {
                final item = wishlist[index];
                return ListTile(
                  leading: item.returnedImg != null && item.returnedImg!.isNotEmpty
                      ? Image.memory(item.returnedImg!)
                      : Icon(Icons.image_not_supported),
                  title: Text(item.productName ?? ''),
                  subtitle: Text('Price: ${item.price?.toStringAsFixed(2) ?? ''} \$'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.add_shopping_cart),
                        onPressed: () => _addToCart(item.productId),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _removeFromWishlist(item.id),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
