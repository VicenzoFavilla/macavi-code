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
  bool _isLoading = false;

  // Helper to show a loading state
  void _setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  // Helper to show user-friendly error messages
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  // Función para iniciar sesión con email y contraseña
  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await _handleSuccessfulLogin(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Error de autenticación: ${e.code} - ${e.message}');
      _showErrorSnackBar('Error: Correo o contraseña incorrectos.');
    } catch (e) {
      print('❌ Error inesperado: $e');
      _showErrorSnackBar('Ocurrió un error inesperado. Inténtalo de nuevo.');
    } finally {
      _setLoading(false);
    }
  }

  // Función para iniciar sesión con Google
  Future<void> _signInWithGoogle() async {
    _setLoading(true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: '1049571319674-tqbkq5708knf9prqtnfvpqq6d89lgptf.apps.googleusercontent.com',
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return; // User cancelled the sign-in
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _handleSuccessfulLogin(userCredential.user!, name: userCredential.user!.displayName);
      }
    } catch (e) {
      print('❌ Error al iniciar sesión con Google: $e');
      _showErrorSnackBar('No se pudo iniciar sesión con Google.');
    } finally {
      _setLoading(false);
    }
  }

  // Función para iniciar sesión con Ios
  Future<void> _signInWithApple() async {
    _setLoading(true);
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );

      final credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: null, // For production, you should generate and use a nonce.
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        await _handleSuccessfulLogin(user, name: appleCredential.givenName);
      }
    } catch (e) {
      print("❌ Error Apple Sign-In: $e");
      _showErrorSnackBar('No se pudo iniciar sesión con Apple.');
    } finally {
      _setLoading(false);
    }
  }

  // Centralized function to handle post-login logic
  Future<void> _handleSuccessfulLogin(User user, {String? name}) async {
    final String uid = user.uid;
    final String? token = await user.getIdToken();

    print('✅ Usuario autenticado, UID: $uid');
    print('🔑 Token de usuario: $token');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', uid);
    await prefs.setString('user_email', user.email ?? '');
    await prefs.setString('user_token', token ?? '');
    if (name != null) {
      await prefs.setString('user_name', name);
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/menu', arguments: uid);
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  Image.asset(
                    'assets/logomacavi.png',
                    width: 100,
                    height: 100,
                  ),
                  const Text(
                    'INICIAR SESIÓN',
                    style: TextStyle(
                      fontFamily: 'NewGroteskSquare',
                      fontSize: 50,
                      color: Color.fromARGB(255, 233, 73, 25),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                              return 'Por favor ingrese su correo';
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
                          onPressed: _isLoading ? null : _submitLogin,
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
                          onPressed: _isLoading ? null : _signInWithGoogle,
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
                          onPressed: _isLoading ? null : _signInWithApple,
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
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.only(top: 20.0),
                            child: CircularProgressIndicator(),
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
                        builder: (context) => const RegistroScreen(),
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
                  child: const Text(
                    'Registrate',
                    style: TextStyle(
                      fontFamily: 'Poppins',
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
