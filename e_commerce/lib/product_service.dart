import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'product_model.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'product_model.dart';
import 'product_service.dart';
import 'storage_service.dart';

class ProductService {

  final String wishlistUrl = 'http://192.168.100.165:8080/api/customer/wishlist';

  final String cartUrl = 'http://192.168.100.165:8080/api/customer/cart';

  Future<List<Product>> fetchProducts(BuildContext context) async {
    String selectedLanguage = Provider.of<LanguageProvider>(context, listen: false).selectedLanguage;

    final String apiUrl = 'http://192.168.100.165:8080/api/admin/products?lang=$selectedLanguage';
    print("_________________________________________________________________________________________________________________");
    print(selectedLanguage);
    print("_________________________________________________________________________________________________________________");

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      // Décodage direct de la réponse JSON
      final List<dynamic> decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));

      // Conversion de chaque élément de la liste en un objet Product
      return decodedResponse.map((dynamic item) => Product.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }


  Future<List<Product>> fetchWishlist(int userId,BuildContext context) async {
    String selectedLanguage = Provider.of<LanguageProvider>(context, listen: false).selectedLanguage;

    final response = await http.get(Uri.parse('$wishlistUrl/$userId?lang=$selectedLanguage'));
    if (response.statusCode == 200) {

      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => Product.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load wishlist');
    }
  }

  Future<void> removeFromWishlist(int itemId) async {
    final response = await http.delete(Uri.parse('$wishlistUrl/$itemId'));
    if (response.statusCode != 204) {
      throw Exception('Failed to remove item from wishlist');
    }
  }

  Future<void> addToCart(int userId, int productId) async {

    final response = await http.post(
      Uri.parse(cartUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, int>{
        'productId': productId,
        'userId': userId,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add item to cart');
    }
  }


}
