import 'dart:convert'; // Ajoutez cet import
import 'dart:typed_data';
import 'traduction.dart';
import 'language_provider.dart';
import 'package:provider/provider.dart';

class Product {
  final int? id;
  final String? name;
  final double? price;
  final String? description;
  final Uint8List? imageBytes;
  final int? categoryId;
  final String? categoryName;
  final int? marqueId;
  final String? marque;
  final String? taille;
  final int? quantiteStock;
  final int? productId;
  final Uint8List? returnedImg; // Ajouter ce champ
  final String? productName; // Ajouter ce champ

  Product({
    this.id,
    this.name,
    this.price,
    this.description,
    this.imageBytes,
    this.categoryId,
    this.categoryName,
    this.marqueId,
    this.marque,
    this.taille,
    this.quantiteStock,
    this.productId,
    this.returnedImg, // Ajouter ce champ
    this.productName, // Ajouter ce champ
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(

      id: json['id'] != null ? json['id'] as int : null,
      name: json['name'] as String?,
      price: json['price'] != null ? json['price'].toDouble() : null,
      description: json['description'] as String?,
      imageBytes: json['byteimg'] != null ? base64Decode(json['byteimg']) : null,
      categoryId: json['categoryId'] != null ? json['categoryId'] as int : null,
      categoryName: json['categoryName'] as String?,
      marqueId: json['marqueId'] != null ? json['marqueId'] as int : null,
      marque: json['marque'] as String?,
      taille: json['taille'] as String?,
      quantiteStock: json['quantiteStock'] != null ? json['quantiteStock'] as int : null,
      productId: json['productId'] != null ? json['productId'] as int : null,
      returnedImg: json['returnedImg'] != null ? base64Decode(json['returnedImg']) : null, // Corriger ce champ
      productName: json['productName'] as String?, // Ajouter ce champ
    );
  }
}
