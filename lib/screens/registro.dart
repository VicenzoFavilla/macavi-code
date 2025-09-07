import 'package:macavi/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Para codificar el JSON

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  _RegistroScreenState createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _nombre = '';

  // Función que envía los datos del usuario al backend para registrar
  Future<void> registrarUsuario() async {
    final url = Uri.parse('https://macavi-1049571319674.southamerica-west1.run.app/registro'); // URL del backend

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': _email,
          'password': _password,
          'nombre': _nombre,
        }),
      );

      print('Código de estado: ${response.statusCode}');
      print('Respuesta del servidor: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Usuario registrado con éxito, UID: ${data['uid']}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario registrado con éxito')),
        );
        Navigator.pop(context);  // Vuelve a la pantalla de inicio de sesión
      } else {
        print('Error en el servidor: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar usuario: ${response.body}')),
        );
      }
    } catch (e) {
      print('Error al conectar con el servidor: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al conectar con el servidor')),
      );
    }
  }

  // Función que maneja el envío del formulario de registro
  void _submitRegistro() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      // Llamamos a la función registrarUsuario
      registrarUsuario();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color.fromARGB(255, 237, 232, 222),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 60), // Espacio superior
                  Image.asset(
                    'assets/logomacavi.png',
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Registro',
                    style: TextStyle(
                      fontFamily: 'NewGroteskSquare',
                      fontSize: 50,
                      color: Color.fromARGB(255, 233, 73, 25),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '¡Crea una cuenta para disfrutar de nuestras smasheadas!',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: Color.fromARGB(255, 233, 73, 25),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Nombre Completo',
                            hintStyle: const TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
                            prefixIcon: const Icon(Icons.person, color: Color.fromARGB(255, 233, 73, 25)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide.none,
                            ),
                            errorStyle: const TextStyle(color: Color.fromARGB(255, 233, 73, 25)),
                          ),
                          style: const TextStyle(color: Color.fromARGB(255, 233, 73, 25), fontFamily: 'Poppins'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su nombre completo';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _nombre = value!;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Correo Electrónico',
                            hintStyle: const TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
                            prefixIcon: const Icon(Icons.email, color: Color.fromARGB(255, 233, 73, 25)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide.none,
                            ),
                            errorStyle: const TextStyle(color: Color.fromARGB(255, 233, 73, 25)),
                          ),
                          style: const TextStyle(color: Color.fromARGB(255, 233, 73, 25), fontFamily: 'Poppins'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                             return 'Por favor ingrese su correo electrónico';
                            }

                            // Dominios permitidos
                          final RegExp emailRegex = RegExp(
                            r'^[\w\.-]+@(?:gmail\.com|hotmail\.com|outlook\.com|yahoo\.com)$',
                          );

                            if (!emailRegex.hasMatch(value)) {
                              return 'Ingrese un correo válido';
                            }

                          return null;},
                          onSaved: (value) {
                            _email = value!;
                          }
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Contraseña',
                            hintStyle: const TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
                            prefixIcon: const Icon(Icons.lock, color: Color.fromARGB(255, 233, 73, 25)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide.none,
                            ),
                            errorStyle: const TextStyle(color: Color.fromARGB(255, 233, 73, 25)),
                          ),
                          style: const TextStyle(color: Color.fromARGB(255, 233, 73, 25), fontFamily: 'Poppins'),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su contraseña';
                            }
                            if (value.length < 8) {
                              return 'La contraseña debe tener al menos 8 caracteres';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _password = value!;
                          },
                        ),
                        const SizedBox(height: 32.0),
                        ElevatedButton(
                          onPressed: _submitRegistro,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),  // Llamar a la función para registrar
                          child: const Text(
                            'Registrarse',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              color: Color.fromARGB(255, 233, 73, 25),
                            ),
                          ),
                        ),
                        const SizedBox(height: 230.0), // Añadimos espacio para evitar superposición
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  '¿Ya tenés una cuenta?',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: Color.fromARGB(255, 233, 73, 25),
                  ),
                ),
                const SizedBox(height: 8.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  child: Text(
                    'Iniciar sesión',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: Color.fromARGB(255, 233, 73, 25),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
