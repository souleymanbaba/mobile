

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'storage_service.dart';

class LoginPage extends StatefulWidget {
@override
_LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
final _formKey = GlobalKey<FormState>();
final TextEditingController _phoneController = TextEditingController();
final TextEditingController _passwordController = TextEditingController();
final StorageService _storageService = StorageService();

Future<void> _login() async {
if (_formKey.currentState!.validate()) {
final String phone = _phoneController.text;
final String password = _passwordController.text;

final response = await http.post(
Uri.parse('http://192.168.100.165:8080/authenticate'),
headers: <String, String>{
'Content-Type': 'application/json; charset=UTF-8',
},
body: jsonEncode(<String, String>{
'username': phone,
'password': password,
}),
);

if (response.statusCode == 200) {
final responseData = jsonDecode(response.body);
final userId = responseData['userId'];
final token = responseData['token'];

await _storageService.saveUser({'userId': userId, 'phone': phone});
await _storageService.saveToken(token);

Navigator.pushReplacementNamed(context, '/'); // Rediriger vers la page des produits
} else {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Invalid phone number or password')),
);
}
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
body: Center(
child: SingleChildScrollView(
padding: EdgeInsets.all(32.0),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
Icons.person,
size: 100,
color: Colors.blue,
),
SizedBox(height: 20),
Text(
'Welcome Back!',
style: TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
color: Colors.blue,
),
),
SizedBox(height: 10),
Text(
'Login to continue',
style: TextStyle(
fontSize: 16,
color: Colors.grey,
),
),
SizedBox(height: 30),
Form(
key: _formKey,
child: Column(
children: [
TextFormField(
controller: _phoneController,
decoration: InputDecoration(
labelText: 'Phone Number',
prefixIcon: Icon(Icons.phone),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(30.0),
),
),
validator: (value) {
if (value == null || value.isEmpty) {
return 'Please enter your phone number';
}
if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
return 'Please enter a valid phone number';
}
return null;
},
),
SizedBox(height: 20),
TextFormField(
controller: _passwordController,
decoration: InputDecoration(
labelText: 'Password',
prefixIcon: Icon(Icons.lock),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(30.0),
),
),
obscureText: true,
validator: (value) {
if (value == null || value.isEmpty) {
return 'Please enter your password';
}
return null;
},
),
SizedBox(height: 20),
ElevatedButton(
onPressed: _login,
child: Text('Login'),
style: ElevatedButton.styleFrom(
padding: EdgeInsets.symmetric(
horizontal: 50,
vertical: 15,
),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(30.0),
),
),
),
SizedBox(height: 20),
TextButton(
onPressed: () {
Navigator.pushReplacementNamed(context, '/signup');
},
child: Text('Don\'t have an account? Sign up'),
),
],
),
),
],
),
),
),
);
}
}
