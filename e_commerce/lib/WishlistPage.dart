import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'product_model.dart';
import 'product_service.dart';
import 'storage_service.dart';
import 'language_provider.dart';
import 'traduction.dart';

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
        final data = await ProductService().fetchWishlist(userId,context);
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
      await ProductService().removeFromWishlist(productId);
      setState(() {
        wishlist.removeWhere((item) => item.productId == productId);
        successMessage = translate('success_remove_wishlist', Provider.of<LanguageProvider>(context, listen: false).selectedLanguage);
        errorMessage = null;
      });
    } catch (error) {
      setState(() {
        successMessage = null;
        errorMessage = translate('error_remove_wishlist', Provider.of<LanguageProvider>(context, listen: false).selectedLanguage);
      });
      print('Error removing item from wishlist: $error');
    }
  }

  Future<void> _addToCart(int? productId) async {
    if (productId == null || userId == null) return;
    try {
      await ProductService().addToCart(userId!, productId);
      setState(() {
        successMessage = translate('success_add_cart', Provider.of<LanguageProvider>(context, listen: false).selectedLanguage);
        errorMessage = null;
      });
    } catch (error) {
      setState(() {
        successMessage = null;
        errorMessage = translate('error_add_cart', Provider.of<LanguageProvider>(context, listen: false).selectedLanguage);
      });
      print('Error adding item to cart: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    String selectedLanguage = Provider.of<LanguageProvider>(context).selectedLanguage;
    TextDirection textDirection = (selectedLanguage == 'ar') ? TextDirection.rtl : TextDirection.ltr;

    if (loading) {
      return Directionality(
        textDirection: textDirection,
        child: Scaffold(
          appBar: AppBar(title: Text(translate('wishlist', selectedLanguage))),
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (wishlist.isEmpty) {
      return Directionality(
        textDirection: textDirection,
        child: Scaffold(
          appBar: AppBar(title: Text(translate('wishlist', selectedLanguage))),
          body: Center(child: Text(translate('empty_wishlist', selectedLanguage))),
        ),
      );
    }

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        appBar: AppBar(title: Text(translate('wishlist', selectedLanguage))),
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
                    title: Text(item.productName ?? '' ,
                      style: TextStyle(
                        fontFamily: 'YourArabicFontFamily',
                      ),
                      textDirection: textDirection,),
                    subtitle: Text('${translate('price', selectedLanguage)}: ${item.price?.toStringAsFixed(2) ?? ''} \MRU'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.add_shopping_cart),
                          onPressed: () => _addToCart(item.productId),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _removeFromWishlist(item.productId),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
