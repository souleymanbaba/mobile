import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'product_model.dart';
import 'product_service.dart';
import 'storage_service.dart';

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
  Map<int, int> cartItems = {}; // Stocker les éléments du panier
  Set<int> wishlistItems = {}; // Stocker les ID des produits dans la wishlist
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
    futureProducts = _loadProducts();
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    await _checkLoginStatus();
    await _loadCategories();
    await _loadCartItems();
    await _loadWishlistItems();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initialLoad(); // Recharger les données lorsque les dépendances changent
  }

  Future<void> _checkLoginStatus() async {
    final user = await _storageService.getUser();
    setState(() {
      isLoggedIn = user != null;
    });
  }

  Future<List<Product>> _loadProducts() async {
    final products = await ProductService().fetchProducts();
    setState(() {
      allProducts = products;
      filteredProducts = products;
      _updateFilters(products);
    });
    return products;
  }

  Future<void> _loadCategories() async {
    final response = await http.get(Uri.parse('http://192.168.100.165:8080/api/admin/categories'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        categories = [{'id': null, 'name': 'Tous'}, ...data.map((item) => {'id': item['id'], 'name': item['name']}).toList()];
      });
    }
  }

  Future<void> _loadSubCategories(int categoryId) async {
    final response = await http.get(Uri.parse('http://192.168.100.165:8080/api/admin/$categoryId/subcategories'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        subCategories = data.map((item) => {'id': item['id'], 'name': item['name']}).toList();
      });
    }
  }

  Future<void> _loadProductsByCategory(int categoryId) async {
    final response = await http.get(Uri.parse('http://192.168.100.165:8080/api/admin/category/$categoryId'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
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
    setState(() {
      filteredProducts = allProducts.where((product) {
        final matchesSearch = product.name?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false;
        final matchesBrand = selectedBrand == null || selectedBrand == 'Tous' || product.marque == selectedBrand;
        final matchesSize = selectedSize == null || selectedSize == 'Tous' || product.taille == selectedSize;
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
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> cartData = jsonDecode(response.body);
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
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> wishlistData = jsonDecode(response.body);
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
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, int>{
          'productId': productId,
          'userId': userId,
        }),
      );
      if (response.statusCode == 200) {
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
      if (response.statusCode == 200) {
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
          cartItems[productId] = (cartItems[productId] ?? 0) + 1; // Ajouter une nouvelle quantité
        });
        await _loadCartItems(); // Recharger toutes les données après l'ajout au panier
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Produit ajouté au panier!')),
        );
      } else {
        print('Failed to add to cart: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ajout au panier.')),
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
          wishlistItems.add(productId); // Ajouter l'élément aux favoris
        });
        await _loadWishlistItems(); // Recharger toutes les données après l'ajout aux favoris
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Produit ajouté aux favoris!')),
        );
        Navigator.pushNamed(context, '/wishlist');
      } else {
        print('Failed to add to favorites: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ajout aux favoris.')),
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

  void _onCategoryChanged(int? categoryId) async {
    setState(() {
      selectedCategoryId = categoryId;
      selectedSubCategoryId = null;
      subCategories = [];
    });

    if (categoryId == null) {
      await _loadProducts(); // Load initial products if 'Tous' is selected
    } else {
      await _loadSubCategories(categoryId); // Load sub-categories if a category is selected
      await _loadProductsByCategory(categoryId); // Load products by category
    }
  }

  void _onSubCategoryChanged(int? subCategoryId) async {
    setState(() {
      selectedSubCategoryId = subCategoryId;
    });

    if (subCategoryId != null) {
      await _loadProductsByCategory(subCategoryId); // Load products by sub-category
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Produits'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
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
                    hint: Text('Sélectionner une catégorie'),
                    value: selectedCategoryId,
                    onChanged: _onCategoryChanged,
                    items: categories.map((category) {
                      return DropdownMenuItem<int?>(
                        value: category['id'] as int?,
                        child: Text(category['name']),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(width: 10),
                if (selectedCategoryId != null && subCategories.isNotEmpty)
                  Expanded(
                    child: DropdownButton<int?>(
                      isExpanded: true,
                      hint: Text('Sélectionner une sous-catégorie'),
                      value: selectedSubCategoryId,
                      onChanged: _onSubCategoryChanged,
                      items: subCategories.map((subCategory) {
                        return DropdownMenuItem<int?>(
                          value: subCategory['id'] as int?,
                          child: Text(subCategory['name']),
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
                    hint: Text('Sélectionner une marque'),
                    value: selectedBrand,
                    onChanged: (value) {
                      setState(() {
                        selectedBrand = value;
                        _filterProducts();
                      });
                    },
                    items: ['Tous', ...brands].map((String brand) {
                      return DropdownMenuItem<String>(
                        value: brand,
                        child: Text(brand),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Text('Sélectionner une taille'),
                    value: selectedSize,
                    onChanged: (value) {
                      setState(() {
                        selectedSize = value;
                        _filterProducts();
                      });
                    },
                    items: ['Tous', ...sizes].map((String size) {
                      return DropdownMenuItem<String>(
                        value: size,
                        child: Text(size),
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
                labelText: 'Rechercher par nom',
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
                  return Center(child: Text('No products available'));
                } else {
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Nombre de cartes par ligne
                      childAspectRatio: 0.8, // Ajuster selon les besoins
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
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isInWishlist ? Icons.favorite : Icons.favorite_border,
                                    ),
                                    onPressed: () => _addToFavorites(product.id!),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                '${product.price?.toStringAsFixed(2) ?? ''} \$',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
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


                                    onPressed: () => _decreaseQuantity(product.id!),
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
      bottomNavigationBar: isLoggedIn ? BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.shopping_cart),
                  onPressed: () async {
                    await Navigator.pushNamed(context, '/cart');
                    await _initialLoad(); // Recharger toutes les données après la navigation
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
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.favorite_border),
                  onPressed: () async {
                    await Navigator.pushNamed(context, '/wishlist');
                    await _initialLoad(); // Recharger toutes les données après la navigation
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
              ],
            ),
            IconButton(
              icon: Icon(Icons.receipt),
              onPressed: () async {
                await Navigator.pushNamed(context, '/orders');
                await _initialLoad(); // Recharger toutes les données après la navigation
              },
            ),
          ],
        ),
      ) : null,
    );
  }
}
