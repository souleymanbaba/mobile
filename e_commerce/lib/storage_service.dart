import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String TOKEN = 'ecom-token';
  static const String USER = 'ecom-user';
  static const String LANG = 'lang';
  static const String LANG_KEYA = 'selectedLanguage';

  Future<void> saveToken(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(TOKEN);
    await prefs.setString(TOKEN, token);
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(USER);
    await prefs.setString(USER, json.encode(user));
  }

  Future<String> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(TOKEN) ?? '';
  }

  Future<Map<String, dynamic>?> getUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString(USER);
    return user != null && user.isNotEmpty ? Map<String, dynamic>.from(json.decode(user)) : null;
  }

  Future<String?> getUserId() async {
    final user = await getUser();
    return user != null ? user['userId'] : null;
  }

  Future<int?> getUserIdd() async {
    final user = await getUser();
    return user != null ? user['userId'] : null;
  }

  Future<void> signOut() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(TOKEN);
    await prefs.remove(USER);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token.isNotEmpty;
  }

  Future<String> getLang() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(LANG) ?? 'fr';
  }

  Future<String> getLangAdmin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(LANG_KEYA) ?? 'fr';
  }

  Future<void> saveLang(String lang) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(LANG);
    await prefs.setString(LANG, lang);
  }
}
