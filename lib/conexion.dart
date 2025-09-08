import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';  // Importar SharedPreferences

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Función para almacenar el token
  Future<void> storeUserData(String token, String userId, String userEmail) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    // 🔥 Guardar también el ID y el email del usuario
    await prefs.setString('user_id', userId);
    await prefs.setString('user_email', userEmail);
  }

  Future<void> login() async {
    // URL del endpoint del backend
    const String url = 'https://macavi-1049571319674.southamerica-west1.run.app/api/login';

    // Realizar la solicitud POST al backend
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': _emailController.text,  // Obtener el email del usuario
        'password': _passwordController.text,  // Obtener la contraseña del usuario
      }),
    );

    // Manejar la respuesta
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      final String token = data['token'];
      // Asumo que la respuesta del login también incluye el id y el email del usuario
      final String userId = data['user']['id']; 
      final String userEmail = data['user']['email'];

      // Almacenar todos los datos del usuario
      await storeUserData(token, userId, userEmail);

      // Navegar a la siguiente pantalla
      Navigator.pushReplacementNamed(context, '/menu');
    } else {
      // Mostrar un error en caso de que el login falle
      print('Error en el login: ${response.body}');
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Error'),
          content: Text('Error al iniciar sesión.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: login,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
