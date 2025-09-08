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
    final prefs = await SharedPreferences.getInstance();
    // Esperamos un momento para asegurar que cualquier login previo haya guardado los datos
    await Future.delayed(const Duration(milliseconds: 500));
    final String? uid = prefs.getString('user_id');

    print("🔎 UID encontrado en Splash: $uid");

    if (!mounted) return;

    if (uid != null) {
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
  final appLinks = AppLinks();

  appLinks.uriLinkStream.listen((Uri uri) async {
    await _procesarDeepLinkGlobal(uri);
  }, onError: (err) {
    print("❌ Error en Deep Link (stream): $err");
  });

  try {
    // CORRECCIÓN: El método fue renombrado en la nueva versión del paquete.
    final Uri? initialLink = await appLinks.getInitialLink();
    if (initialLink != null) {
      await _procesarDeepLinkGlobal(initialLink);
    }
  } catch (e) {
    print("❌ Error al obtener initial app link: $e");
  }
}

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

  await prefs.setBool('desde_pago', true);

  final uid = prefs.getString('user_id'); // Asegurate que esto diga user_id ✅

  print("🧑 UID usado para vaciar carrito: $uid"); // 👈 ESTE ES EL PRINT

  final url = Uri.parse('https://macavi-1049571319674.southamerica-west1.run.app/usuario/$uid/carrito');

  try {
    final response = await http.delete(url);
    if (response.statusCode == 200) {
      print("🧹 Carrito vaciado correctamente desde Deep Link");
    } else {
      print("❌ Error al vaciar el carrito: ${response.body}");
    }
  } catch (e) {
    print("❌ Excepción al vaciar carrito: $e");
  }

  navigatorKey.currentState?.pushReplacementNamed('/gracias');
}

 else {
      print("❌ El pago no fue aprobado correctamente.");
      navigatorKey.currentState?.pushReplacementNamed('/carrito');
    }
  }
}
