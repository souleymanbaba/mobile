// traduction.dart
Map<String, dynamic> translations = {
  "en": {
    "products": "Products",
    "all": "All",
    "search_by_name": "Search by name",
    "select_category": "Select Category",
    "select_sub_category": "Select Sub Category",
    "select_brand": "Select Brand",
    "select_size": "Select Size",
    "price": "Price",
    "add_to_cart": "Add to cart",
    "cart": "Cart",
    "wishlist": "Wishlist",
    "orders": "Orders",
    "remove_from_cart": "Removed from cart",
    "order_placed": "Order placed successfully",
    "order_failed": "Failed to place order. Please try again.",
    "place_order": "Place Order",
    "phone_number": "Phone Number",
    "total_price": "Total Price",
    "cart_empty": "Your cart is empty.",
    "cancel": "Cancel",
    "fill_all_fields": "Please fill in all the fields",
     "empty_wishlist": "Your wishlist is empty.",
    "no_orders": "No orders available.",
    "amount": "Amount",
    "number": "Number",
    "date": "Date",
    "status": "Status",
    "actions": "Actions",
    "cart_items": "Cart Items",
    "quantity": "Quantity",
  },
  "ar": {
    "orders": "الطلبات",
    "no_orders": "لا توجد طلبات متاحة.",
    "amount": "المبلغ",
    "number": "الرقم",
    "date": "التاريخ",
    "status": "الحالة",
    "actions": "الإجراءات",
    "cart_items": "عناصر السلة",
    "quantity": "الكمية",
    "empty_wishlist": "قائمة رغباتك فارغة.",
    "products": "منتجات",
    "all": "الجميع",
    "search_by_name": "البحث عن طريق الاسم",
    "select_category": "اختر الفئة",
    "select_sub_category": "اختر الفئة الفرعية",
    "select_brand": "اختر العلامة التجارية",
    "select_size": "اختر الحجم",
    "price": "السعر",
    "add_to_cart": "أضف إلى السلة",
    "cart": "عربة التسوق",
    "wishlist": "قائمة الرغبات",
    "orders": "الطلبات",
    "remove_from_cart": "تمت الإزالة من السلة",
    "order_placed": "تم تقديم الطلب بنجاح",
    "order_failed": "فشل في تقديم الطلب. حاول مرة أخرى.",
    "place_order": "تقديم الطلب",
    "phone_number": "رقم الهاتف",
    "total_price": "السعر الإجمالي",
    "cart_empty": "عربة التسوق فارغة.",
    "cancel": "إلغاء",
    "fill_all_fields": "يرجى ملء جميع الحقول",
  },
  "fr": {
    
    "products": "Produits",
    "all": "Tous",
    "search_by_name": "Rechercher par nom",
    "select_category": "Sélectionner une catégorie",
    "select_sub_category": "Sélectionner une sous-catégorie",
    "select_brand": "Sélectionner une marque",
    "select_size": "Sélectionner une taille",
    "price": "Prix",
    "add_to_cart": "Ajouter au panier",
    "cart": "Panier",
    "wishlist": "Liste de souhaits",
    "orders": "Commandes",
    "remove_from_cart": "Supprimé du panier",
    "order_placed": "Commande passée avec succès",
    "order_failed": "Échec de la commande. Veuillez réessayer.",
    "place_order": "Passer la commande",
    "phone_number": "Numéro de téléphone",
    "total_price": "Prix total",
    "cart_empty": "Votre panier est vide.",
    "cancel": "Annuler",
    "fill_all_fields": "Veuillez remplir tous les champs",
    "empty_wishlist": "Votre liste de souhaits est vide.",
  }
};

String translate(String key, String languageCode) {
  return translations[languageCode]?[key] ?? key;
}