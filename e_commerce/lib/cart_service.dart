import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'language_provider.dart';

class CartService {
  static const String baseUrl = 'http://192.168.100.165:8080/api/customer';

  Future<Map<String, dynamic>> fetchCartData(int userId,BuildContext context) async {
    String selectedLanguage = Provider.of<LanguageProvider>(context, listen: false).selectedLanguage;

    final response = await http.get(Uri.parse('$baseUrl/cart/$userId?lang=$selectedLanguage'));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load cart data');
    }
  }

  Future<void> updateQuantity(int userId, int productId, String endpoint) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'productId': productId, 'userId': userId}),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to update quantity');
    }
  }

  Future<void> removeCartItem(int cartItemId) async {
    final response = await http.delete(Uri.parse('$baseUrl/items/$cartItemId'));
    if (response.statusCode != 204) {
      throw Exception('Failed to remove item');
    }
  }

  Future<void> placeOrder(Map<String, dynamic> orderData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/placeOrder'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(orderData),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to place order');
    }
  }
}
