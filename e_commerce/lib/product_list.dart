import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert'; // Pour jsonDecode
import 'package:http/http.dart' as http; // Pour les requêtes HTTP
import 'product_model.dart';
import 'product_service.dart';
import 'storage_service.dart';
import 'language_provider.dart';
import 'traduction.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Pour stocker la langue sélectionnée

class ProductList extends StatefulWidget {
  @override
  _ProductListState createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  late Future<List<Product>> futureProducts;
  final StorageService _storageService = StorageService();
  bool isLoggedIn = false;
  List<Product> allProducts = [];
  List<Product> filteredProducts = [];
  Map<int, int> cartItems = {};
  Set<int> wishlistItems = {};
  String searchQuery = '';
  String? selectedBrand;
  String? selectedSize;
  int? selectedCategoryId;
  int? selectedSubCategoryId;
  List<String> brands = [];
  List<String> sizes = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> subCategories = [];
  int cartCount = 0;
  int wishlistCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSelectedLanguage();
    futureProducts = _loadProducts();
    _initialLoad();
  }

  Future<void> _loadSelectedLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? selectedLanguage = prefs.getString('selectedLanguage');
    if (selectedLanguage != null) {
      Provider.of<LanguageProvider>(context, listen: false).setLanguage(selectedLanguage);
    }
  }

  Future<void> _saveSelectedLanguage(String language) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', language);
  }

  Future<void> _initialLoad() async {
    await _checkLoginStatus();
    await _loadCategories();
    await _loadCartItems();
    await _loadWishlistItems();
  }

  Future<void> _checkLoginStatus() async {
    final user = await _storageService.getUser();
    setState(() {
      isLoggedIn = user != null;
    });
  }

  Future<List<Product>> _loadProducts() async {
    final products = await ProductService().fetchProducts(context);
    setState(() {
      allProducts = products;
      filteredProducts = products;
      _updateFilters(products);
    });
    return products;
  }

  Future<void> _loadCategories() async {
    String selectedLanguage = Provider.of<LanguageProvider>(context, listen: false).selectedLanguage;
    final response = await http.get(Uri.parse('http://192.168.100.165:8080/api/admin/categories?lang=$selectedLanguage'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      setState(() {
        categories = [{'id': null, 'name': translate('all', selectedLanguage)}]
          ..addAll(data.map((item) => {'id': item['id'], 'name': translate(item['name'], selectedLanguage)}).toList());
      });
    }
  }

  Future<void> _loadSubCategories(int categoryId) async {
    String selectedLanguage = Provider.of<LanguageProvider>(context, listen: false).selectedLanguage;
    final response = await http.get(Uri.parse('http://192.168.100.165:8080/api/admin/$categoryId/subcategories?lang=$selectedLanguage'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      setState(() {
        subCategories = [{'id': null, 'name': translate('all', selectedLanguage)}]
          ..addAll(data.map((item) => {'id': item['id'], 'name': translate(item['name'], selectedLanguage)}).toList());
      });
    }
  }

  Future<void> _loadProductsByCategory(int categoryId) async {
    String selectedLanguage = Provider.of<LanguageProvider>(context, listen: false).selectedLanguage;
    final response = await http.get(Uri.parse('http://192.168.100.165:8080/api/admin/category/$categoryId?lang=$selectedLanguage'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      final products = data.map((item) => Product.fromJson(item)).toList();
      setState(() {
        allProducts = products;
        filteredProducts = products;
        _updateFilters(products);
      });
    } else {
      setState(() {
        allProducts = [];
        filteredProducts = [];
        brands = [];
        sizes = [];
      });
    }
  }

  void _updateFilters(List<Product> products) {
    brands = products.map((p) => p.marque ?? '').toSet().toList();
    sizes = products.map((p) => p.taille ?? '').toSet().toList();
  }

  void _filterProducts() {
    String selectedLanguage = Provider.of<LanguageProvider>(context, listen: false).selectedLanguage;
    setState(() {
      filteredProducts = allProducts.where((product) {
        final matchesSearch = product.name?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false;
        final matchesBrand = selectedBrand == null || selectedBrand == translate('all', selectedLanguage) || product.marque == selectedBrand;
        final matchesSize = selectedSize == null || selectedSize == translate('all', selectedLanguage) || product.taille == selectedSize;
        return matchesSearch && matchesBrand && matchesSize;
      }).toList();
    });
  }

  Future<void> _loadCartItems() async {
    final user = await _storageService.getUser();
    if (user != null) {
      final userId = user['userId'];
      final response = await http.get(
        Uri.parse('http://192.168.100.165:8080/api/customer/cart/$userId'),
        headers: <String, String>{
          'Content-Type': 'application/json;',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> cartData = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> items = cartData['cartItems'];
        final Map<int, int> cartItems = {};
        for (var item in items) {
          cartItems[item['productId']] = item['quantity'];
        }
        setState(() {
          this.cartItems = cartItems;
          cartCount = items.length;
        });
      } else {
        throw Exception('Failed to load cart items');
      }
    }
  }

  Future<void> _loadWishlistItems() async {
    final user = await _storageService.getUser();
    if (user != null) {
      final userId = user['userId'];
      final response = await http.get(
        Uri.parse('http://192.168.100.165:8080/api/customer/wishlist/$userId'),
        headers: <String, String>{
          'Content-Type': 'application/json; ',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> wishlistData = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          wishlistItems = wishlistData.map((item) => item['productId'] as int).toSet();
          wishlistCount = wishlistData.length;
        });
      } else {
        throw Exception('Failed to load wishlist items');
      }
    }
  }

  Future<void> _increaseQuantity(int productId) async {
    final user = await _storageService.getUser();
    if (user != null) {
      final userId = user['userId'];
      final response = await http.post(
        Uri.parse('http://192.168.100.165:8080/api/customer/addition'),
        headers: <String, String>{
          'Content-Type': 'application/json ',
        },
        body: jsonEncode(<String, int>{
          'productId': productId,
          'userId': userId,
        }),
      );

      print("_________________________________________________________________________________________________________________");
print(productId);
print(userId);
      print("_________________________________________________________________________________________________________________");

      if (response.statusCode == 201) {
        setState(() {
          cartItems[productId] = (cartItems[productId] ?? 0) + 1;
        });
        await _loadCartItems();
      } else {
        print('Failed to increase quantity: ${response.body}');
        throw Exception('Failed to increase product quantity');
      }
    }
  }

  Future<void> _decreaseQuantity(int productId) async {
    final user = await _storageService.getUser();
    if (user != null) {
      final userId = user['userId'];
      final response = await http.post(
        Uri.parse('http://192.168.100.165:8080/api/customer/deduction'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, int>{
          'productId': productId,
          'userId': userId,
        }),
      );
      if (response.statusCode == 201) {
        setState(() {
          final currentQuantity = cartItems[productId] ?? 0;
          if (currentQuantity > 0) {
            cartItems[productId] = currentQuantity - 1;
          }
        });
        await _loadCartItems();
      } else {
        print('Failed to decrease quantity: ${response.body}');
        throw Exception('Failed to decrease product quantity');
      }
    }
  }

  Future<void> _addToCart(int productId) async {
    final user = await _storageService.getUser();
    if (user == null) {
      Navigator.pushNamed(context, '/login');
    } else {
      final userId = user['userId'];
      final response = await http.post(
        Uri.parse('http://192.168.100.165:8080/api/customer/cart'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, int>{
          'productId': productId,
          'userId': userId,
        }),
      );

      if (response.statusCode == 201) {
        setState(() {
          cartItems[productId] = (cartItems[productId] ?? 0) + 1;
        });
        await _loadCartItems();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translate('add_to_cart', Provider.of<LanguageProvider>(context).selectedLanguage))),
        );
      } else {
        print('Failed to add to cart: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translate('sync_pending', Provider.of<LanguageProvider>(context).selectedLanguage))),
        );
      }
    }
  }

  Future<void> _addToFavorites(int productId) async {
    final user = await _storageService.getUser();
    if (user == null) {
      Navigator.pushNamed(context, '/login');
    } else {
      final userId = user['userId'];
      final response = await http.post(
        Uri.parse('http://192.168.100.165:8080/api/customer/wishlist'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, int>{
          'productId': productId,
          'userId': userId,
        }),
      );

      if (response.statusCode == 201) {
        setState(() {
          wishlistItems.add(productId);
        });
        await _loadWishlistItems();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translate('wishlist', Provider.of<LanguageProvider>(context).selectedLanguage))),
        );
      } else {
        print('Failed to add to favorites: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translate('sync_pending', Provider.of<LanguageProvider>(context).selectedLanguage))),
        );
      }
    }
  }

  Future<void> _removeFromFavorites(int productId) async {
    final user = await _storageService.getUser();
    if (user == null) {
      Navigator.pushNamed(context, '/login');
    } else {
      final userId = user['userId'];
      final response = await http.delete(
        Uri.parse('http://192.168.100.165:8080/api/customer/removedd/$productId/$userId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          wishlistItems.remove(productId);
        });
        await _loadWishlistItems();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translate('wishlist', Provider.of<LanguageProvider>(context).selectedLanguage))),
        );
      } else {
        print('Failed to remove from favorites: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression des favoris.')),
        );
      }
    }
  }

  Future<void> _removeFromCarttt(int productId) async {
    final user = await _storageService.getUser();
    if (user == null) {
      Navigator.pushNamed(context, '/login');
    } else {
      final userId = user['userId'];
      final response = await http.delete(
        Uri.parse('http://192.168.100.165:8080/api/customer/removee/$productId/$userId'),
        headers: <String, String>{
          'Content-Type': 'application/json; ',
        },
      );

      if (response.statusCode == 200) {
        await _loadCartItems(); // Recharger toutes les données après la suppression des favoris
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Produit supprimé des Cart!')),
        );
      } else {
        print('Failed to remove from favorites: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression des favoris.')),
        );
      }
    }
  }

  Future<void> _sendProductToEndpoint(int productId) async {
    final user = await _storageService.getUser();
    if (user == null) {
      Navigator.pushNamed(context, '/login');
    } else {
      final userId = user['userId'];
      final response = await http.post(
        Uri.parse('http://192.168.100.165:8080/api/customer/wishlist'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, int>{
          'productId': productId,
          'userId': userId,
        }),
      );

      if (response.statusCode == 201) {
        setState(() {
          wishlistItems.add(productId); // Ajouter l'élément à la liste de souhaits
        });
        await _loadWishlistItems(); // Recharger toutes les données après l'ajout à la wishlist
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Produit envoyé avec succès!')),
        );
      } else {
        print('Failed to send product to endpoint: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Le produit est déjà dans votre liste de souhaits')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await _storageService.signOut();
    setState(() {
      isLoggedIn = false;
    });
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        String selectedLanguage = languageProvider.selectedLanguage;
        TextDirection textDirection = (selectedLanguage == 'ar') ? TextDirection.rtl : TextDirection.ltr;

        return Directionality(
          textDirection: textDirection,
          child: Scaffold(
            appBar: AppBar(
              title: Text(translate('products', selectedLanguage)),
              actions: [
                if (isLoggedIn)
                  IconButton(
                    icon: Icon(Icons.logout),
                    onPressed: _logout,
                  )
                else
                  IconButton(
                    icon: Icon(Icons.account_circle),
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                  ),
                PopupMenuButton<String>(
                  onSelected: (String languageCode) async {
                    languageProvider.setLanguage(languageCode);
                    await _saveSelectedLanguage(languageCode);
                    await _loadCategories();
                    await _loadProducts();// Recharger les catégories avec la nouvelle langue
                    if (selectedCategoryId != null) {
                      await _loadSubCategories(selectedCategoryId!); // Recharger les sous-catégories avec la nouvelle langue
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'en',
                        child: Text(
                          'English',
                          style: TextStyle(
                            color: selectedLanguage == 'en' ? Colors.blue : null,
                          ),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'fr',
                        child: Text(
                          'Français',
                          style: TextStyle(
                            color: selectedLanguage == 'fr' ? Colors.blue : null,
                          ),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'ar',
                        child: Text(
                          'العربية',
                          style: TextStyle(
                            color: selectedLanguage == 'ar' ? Colors.blue : null,
                          ),
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<int?>(
                          isExpanded: true,
                          hint: Text(translate('select_category', selectedLanguage)),
                          value: selectedCategoryId,
                          onChanged: (categoryId) {
                            setState(() {
                              selectedCategoryId = categoryId;
                              selectedSubCategoryId = null;
                              subCategories = [];
                            });

                            if (categoryId == null) {
                              _loadProducts();
                            } else {
                              _loadSubCategories(categoryId);
                              _loadProductsByCategory(categoryId);
                            }
                          },
                          items: categories.map((category) {
                            return DropdownMenuItem<int?>(
                              value: category['id'] as int?,
                              child: Text(
                                category['name'],
                                style: TextStyle(
                                  fontFamily: 'YourArabicFontFamily',
                                ),
                                textDirection: textDirection,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(width: 10),
                      if (selectedCategoryId != null && subCategories.isNotEmpty)
                        Expanded(
                          child: DropdownButton<int?>(
                            isExpanded: true,
                            hint: Text(translate('select_sub_category', selectedLanguage)),
                            value: selectedSubCategoryId,
                            onChanged: (subCategoryId) {
                              setState(() {
                                selectedSubCategoryId = subCategoryId;
                              });

                              if (subCategoryId != null) {
                                _loadProductsByCategory(subCategoryId);
                              }
                            },
                            items: subCategories.map((subCategory) {
                              return DropdownMenuItem<int?>(
                                value: subCategory['id'] as int?,
                                child: Text(
                                  subCategory['name'],
                                  style: TextStyle(
                                    fontFamily: 'YourArabicFontFamily',
                                  ),
                                  textDirection: textDirection,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: Text(translate('select_brand', selectedLanguage)),
                          value: selectedBrand,
                          onChanged: (value) {
                            setState(() {
                              selectedBrand = value;
                              _filterProducts();
                            });
                          },
                          items: [translate('all', selectedLanguage), ...brands].map((String brand) {
                            return DropdownMenuItem<String>(
                              value: brand,
                              child: Text(
                                brand,
                                style: TextStyle(
                                  fontFamily: 'YourArabicFontFamily',
                                ),
                                textDirection: textDirection,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: Text(translate('select_size', selectedLanguage)),
                          value: selectedSize,
                          onChanged: (value) {
                            setState(() {
                              selectedSize = value;
                              _filterProducts();
                            });
                          },
                          items: [translate('all', selectedLanguage), ...sizes].map((String size) {
                            return DropdownMenuItem<String>(
                              value: size,
                              child: Text(
                                size,
                                style: TextStyle(
                                  fontFamily: 'YourArabicFontFamily',
                                ),
                                textDirection: textDirection,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        _filterProducts();
                      });
                    },
                    decoration: InputDecoration(
                      labelText: translate('search_by_name', selectedLanguage),
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Product>>(
                    future: futureProducts,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text(translate('no_products', selectedLanguage)));
                      } else {
                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            Product product = filteredProducts[index];
                            bool isInWishlist = wishlistItems.contains(product.id);
                            return Card(
                              elevation: 5,
                              margin: EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: product.imageBytes != null && product.imageBytes!.isNotEmpty
                                        ? Image.memory(
                                      product.imageBytes!,
                                      fit: BoxFit.cover,
                                    )
                                        : Placeholder(),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          product.name ?? '',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            fontFamily: 'YourArabicFontFamily',
                                          ),
                                          textDirection: textDirection,
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            isInWishlist ? Icons.favorite : Icons.favorite_border,
                                          ),
                                          onPressed: () {
                                            if (isInWishlist) {
                                              _removeFromFavorites(product.id!);
                                            } else {
                                              _addToFavorites(product.id!);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text(
                                      '${product.price?.toStringAsFixed(2) ?? ''} \MRU',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontFamily: 'YourArabicFontFamily',
                                      ),
                                      textDirection: textDirection,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: cartItems.containsKey(product.id)
                                        ? Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.remove),
                                          onPressed: () {
                                            if (cartItems[product.id] == 1) {
                                              _removeFromCarttt(product.id!);
                                            } else {
                                              _decreaseQuantity(product.id!);
                                            }
                                          },
                                        ),
                                        Text('${cartItems[product.id]}'),
                                        IconButton(
                                          icon: Icon(Icons.add),
                                          onPressed: () => _increaseQuantity(product.id!),
                                        ),
                                      ],
                                    )
                                        : ElevatedButton(
                                      onPressed: () => _addToCart(product.id!),
                                      child: Icon(Icons.add_shopping_cart),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            bottomNavigationBar: isLoggedIn
                ? BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(Icons.shopping_cart),
                        onPressed: () async {
                          await Navigator.pushNamed(context, '/cart');
                          await _initialLoad();
                        },
                      ),
                      if (cartCount > 0)
                        Positioned(
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            constraints: BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: Text(
                              '$cartCount',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.favorite_border),
                    onPressed: () async {
                      await Navigator.pushNamed(context, '/wishlist');
                      await _initialLoad();
                    },
                  ),
                  if (wishlistCount > 0)
                    Positioned(
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          '$wishlistCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: Icon(Icons.receipt),
                    onPressed: () async {
                      await Navigator.pushNamed(context, '/orders');
                      await _initialLoad();
                    },
                  ),
                ],
              ),
            )
                : null,
          ),
        );
      },
    );
  }
}
