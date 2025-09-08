import 'package:macavi/screens/registro.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  // Función para iniciar sesión con email y contraseña
  Future<void> login(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user != null) {
        final String uid = user.uid;
        final String? token = await user.getIdToken();

        print('✅ Usuario autenticado, UID: $uid');
        print('🔑 Token de usuario: $token');

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', uid);
        await prefs.setString('user_email', email);
        await prefs.setString('user_token', token ?? '');

        Navigator.pushReplacementNamed(context, '/menu', arguments: uid);
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Error de autenticación: ${e.code} - ${e.message}');
    } catch (e) {
      print('❌ Error inesperado: $e');
    }
  }

  // Función para iniciar sesión con Google
  Future<void> _signInWithGoogle() async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email'],
      serverClientId: '1049571319674-tqbkq5708knf9prqtnfvpqq6d89lgptf.apps.googleusercontent.com',
    );

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) return;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    final User? user = userCredential.user;

    if (user != null) {
      final String uid = user.uid;
      final String? token = await user.getIdToken();

      print('✅ Usuario autenticado con Google, UID: $uid');
      print('🔑 Token de usuario: $token');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', uid);
      await prefs.setString('user_email', user.email ?? '');
      await prefs.setString('user_token', token ?? '');
      await prefs.setString('user_name', user.displayName ?? 'Usuario');

      Navigator.pushReplacementNamed(context, '/menu', arguments: uid);
    }
  } catch (e) {
    print('❌ Error al iniciar sesión con Google: $e');
  }
}

  // Función para iniciar sesión con Ios
  Future<void> _signInWithApple() async {
  try {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );

    final oAuthProvider = OAuthProvider("apple.com");
    final credential = oAuthProvider.credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      final token = await user.getIdToken();
      final uid = user.uid;

      print("🍎 Apple UID: $uid");
      print("🔑 Token: $token");

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', uid);
      await prefs.setString('user_email', user.email ?? '');
      await prefs.setString('user_token', token ?? '');
      await prefs.setString('user_name', appleCredential.givenName ?? 'Usuario');

      Navigator.pushReplacementNamed(context, '/menu', arguments: uid);
    }
  } catch (e) {
    print("❌ Error Apple Sign-In: $e");
  }
}

  // Función que maneja el envío del formulario
  void _submitLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      login(_email, _password);
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
                  const SizedBox(height: 60),
                  Image.asset(
                    'assets/logomacavi.png',
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'INICIAR SESIÓN',
                    style: TextStyle(
                      fontFamily: 'NewGroteskSquare',
                      fontSize: 50,
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
                            hintText: 'Correo Electrónico',
                            prefixIcon: const Icon(Icons.person, color: Colors.black),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su correo electrónico';
                            }
                            return null;
                          },
                          onSaved: (value) => _email = value!,
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock, color: Colors.black),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su contraseña';
                            }
                            return null;
                          },
                          onSaved: (value) => _password = value!,
                        ),
                        const SizedBox(height: 25.0),
                        ElevatedButton(
                          onPressed: _submitLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 233, 73, 25),
                            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          ),
                          child: const Text(
                            'INICIAR SESIÓN',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 30.0),
                        ElevatedButton.icon(
                          onPressed: _signInWithGoogle,
                          icon: const Icon(Icons.login, color: Colors.white),
                          label: const Text(
                            'INICIAR SESIÓN CON GOOGLE',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 233, 73, 25),
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          ),
                        ),
                        const SizedBox(height: 30.0),
                        ElevatedButton.icon(
                          onPressed: _signInWithApple,
                          icon: const Icon(Icons.login, color: Colors.white),
                          label: const Text(
                            'INICIAR SESIÓN CON IOS',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 233, 73, 25),
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          ),
                        ),
                        const SizedBox(height: 230.0),
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
                  '¿No tenés una cuenta?',
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
                        builder: (context) => RegistroScreen(),
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
                    'Registrate',
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
