import 'package:macavi/screens/PostCompraScreen.dart';
import 'package:macavi/screens/login.dart';
import 'package:macavi/screens/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Centralized backend URL to avoid hardcoding.
const String BACKEND_BASE_URL = 'https://macavi-1049571319674.southamerica-west1.run.app';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e is FirebaseException && e.code == 'duplicate-app') {
      print('⚠️ Firebase ya estaba inicializado.');
    } else {
      print('❌ Error initializing Firebase: $e');
    }
  }

  runApp(const MyApp());

  // 🔁 Deep link handler después de montar la app
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _handleDeepLinksGlobal();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        if (settings.name == '/menu') {
          // ✅ Extraer el userId de los argumentos de la ruta
          final userId = settings.arguments as String?;
          if (userId != null) {
            return MaterialPageRoute(
              builder: (context) => MenuScreen(userId: userId),
            );
          }
        }
        return null;
      },
      routes: {
        '/': (context) => const LoginScreen(),
        '/splash': (context) => const SplashScreen(),
        '/gracias': (context) => const PostCompraScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _obtenerTokenFCM();
    _navigateToLogin();
  }

  void _obtenerTokenFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    try {
      String? token = await messaging.getToken();
      print("🔹 Token FCM del dispositivo: $token");
    } catch (error) {
      print("❌ Error al obtener el token FCM: $error");
    }
  }

  void _navigateToLogin() async {
    // The Future.delayed is removed as it's a code smell, likely a workaround for a race condition.
    // A direct check is more reliable.
    final prefs = await SharedPreferences.getInstance();
    final String? uid = prefs.getString('user_id');

    print("🔎 UID encontrado en Splash: $uid");

    if (!mounted) return;

    if (uid != null && uid.isNotEmpty) {
      Navigator.pushReplacementNamed(context, '/menu', arguments: uid);
    } else {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 233, 73, 25),
      body: Center(
        child: SizedBox.expand(
          child: Image.asset(
            'assets/pantallacarga.jpg',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

void _handleDeepLinksGlobal() async {
  try {
    final appLinks = AppLinks();

    // Escucha los enlaces que llegan mientras la app está abierta.
    appLinks.uriLinkStream.listen((uri) async {
      print("🔹 Deep Link recibido (stream): $uri");
      try {
        await _procesarDeepLinkGlobal(uri);
      } catch (e) {
        print("❌ Error al procesar deep link desde el stream: $e");
      }
    }, onError: (err) {
      print("❌ Error en el stream de deep links: $err");
    });

    // Obtiene el enlace inicial que abrió la app (cuando estaba cerrada).
    // FIX: The method name depends on the app_links package version.
    // For version 3.x (which you are using), the correct method is `getInitialAppLink()`.
    final Uri? initialLink = await appLinks.getInitialAppLink();
    if (initialLink != null) {
      print("🔹 Deep Link inicial encontrado: $initialLink");
      await _procesarDeepLinkGlobal(initialLink);
    }
  } catch (e) {
    print("❌ Error al inicializar o procesar deep links: $e");
  }
}

/// Attempts to clear the user's cart on the backend.
/// Returns `true` if successful, `false` otherwise.
Future<bool> _vaciarCarritoGlobal() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('user_id');

    if (uid == null || uid.isEmpty) {
      print("⚠️ No se encontró user_id para vaciar el carrito.");
      return false;
    }

    print("🧑 UID usado para vaciar carrito: $uid");

    final url = Uri.parse('$BACKEND_BASE_URL/usuario/$uid/carrito');
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      print("🧹 Carrito vaciado correctamente desde Deep Link");
      return true;
    } else {
      print("❌ Error al vaciar el carrito: ${response.statusCode} ${response.body}");
      return false;
    }
  } catch (e) {
    print("❌ Excepción al vaciar carrito: $e");
    return false;
  }
}

/// Processes a deep link to handle post-payment navigation.
///
/// If the payment was approved, it clears the user's cart and navigates
/// to the "Thank You" screen. Otherwise, it navigates to the main menu.
Future<void> _procesarDeepLinkGlobal(Uri uri) async {
  print("🔹 Deep Link recibido (global): ${uri.toString()}");
  print("📍 URI HOST: ${uri.host}");
  print("📍 URI PATH: ${uri.path}");

  if (uri.host == "menu_screen") {
    final prefs = await SharedPreferences.getInstance();
    final String? uid = prefs.getString('user_id');

    if (uid == null) {
      print("🔴 No hay sesión iniciada. Mostramos login.");
      navigatorKey.currentState?.pushReplacementNamed('/');
      return;
    }

    String? status = uri.queryParameters["status"];
    String? collectionStatus = uri.queryParameters["collection_status"];
    String? paymentId = uri.queryParameters["payment_id"];

    print("🔎 status: $status");
    print("🔎 collectionStatus: $collectionStatus");

    if (status == "approved" && collectionStatus == "approved") {
      print("✅ Pago confirmado con ID: $paymentId");

      // Set a flag that can be used by other parts of the app if needed.
      await prefs.setBool('desde_pago', true);

      // Attempt to clear the cart and navigate.
      await _vaciarCarritoGlobal();

      // Navigate to the "Thank You" screen regardless of cart clearing success,
      // as the payment itself was successful.
      navigatorKey.currentState?.pushReplacementNamed('/gracias');
    } else {
      print("❌ El pago no fue aprobado correctamente. Navegando al menú.");
      // BUG FIX: The '/carrito' route does not exist. Navigate to the main menu instead.
      navigatorKey.currentState?.pushReplacementNamed('/menu', arguments: uid);
    }
  }
}
