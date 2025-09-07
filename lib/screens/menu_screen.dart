import 'dart:async';

import 'package:macavi/screens/perfil.dart';
import 'package:macavi/screens/promo_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'carrito.dart';
import 'BurgerScreen.dart';

const String MENU_BASE    = 'https://macavi-1049571319674.southamerica-west1.run.app';             // hamburguesas, extras
const String BACKEND_BASE = 'https://macavi-backend-1049571319674.southamerica-west1.run.app';     // carrito, promos

class MenuScreen extends StatefulWidget {
  final String userId;

  const MenuScreen({super.key, required this.userId});

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<Map<String, dynamic>> hamburgers = [];
  List<Map<String, dynamic>> bebidas = [];
  Map<String, List<Map<String, dynamic>>> acompanamiento = {}; // Cambiado a un Map
  List<Map<String, dynamic>> carritoProductos = [];
  int puntosTotales = 0;
  bool isLoading = true;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([fetchHamburgers(), fetchExtrasAndDrinks(), fetchCarrito()]);
      if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  void _navigateToCarrito() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CarritoScreen(userId: widget.userId),
    ),
  ).then((_) => fetchCarrito());
}

  Future<void> fetchHamburgers() async {
  final urlHamburguesas = Uri.parse('$MENU_BASE/hamburguesas');
  try {
    final responseHamburguesas = await http.get(urlHamburguesas);

    if (responseHamburguesas.statusCode == 200) {
      final dataHamburguesas = json.decode(responseHamburguesas.body) as List;

      hamburgers = dataHamburguesas.map((item) {
        return {
          'id': item['id'],
          'name': item['name'],
          'price': item['price'],
          'imagen': item['imagen'] ?? 'https://via.placeholder.com/150',
          'ingredients': item['ingredients'] ?? [],
          'extraingredients': item['extraingredients'] ?? [],
          'bebidas': item['bebidas'] ?? [],  // 🔥 ✅ Asegurar que bebidas se almacena correctamente
        };
      }).toList();

      print("✅ Hamburguesas cargadas con bebidas: ${jsonEncode(hamburgers)}"); // 🔥 Debug para verificar en consola
    } else {
      print('❌ Error al cargar hamburguesas: ${responseHamburguesas.statusCode}');
    }
  } catch (e) {
    print('❌ Error al conectar con el servidor: $e');
  }
}

  Future<void> fetchExtrasAndDrinks() async {
  final url = Uri.parse('$MENU_BASE/extras');
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;

      final acompList = data.where((item) {
        final type = item['type']?.toString().trim().toLowerCase();
        return type == 'acompanamiento';
      }).map((item) => Map<String, dynamic>.from(item)).toList();

      print('🧂 Acompañamientos encontrados: ${acompList.length}');

      setState(() {
        acompanamiento = {
          'Todos los Acompañamientos': acompList,
        };
      });
    } else {
      print('❌ Error al cargar extras: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Error al conectar con el servidor: $e');
  }
}


  Map<String, List<Map<String, dynamic>>> groupByCategory(List<Map<String, dynamic>> items) {
  Map<String, List<Map<String, dynamic>>> groupedItems = {
    'Papas': [],
    'Nuggets': [],
    'Aros de Cebolla': [],
    'Dips': [],
  };

  for (var item in items) {
    String name = item['name'].toLowerCase();

    if (name.contains('papa')) {
      groupedItems['Papas']?.add(item);
    } else if (name.contains('nugget')) {
      groupedItems['Nuggets']?.add(item);
    } else if (name.contains('aros')) {
      groupedItems['Aros de Cebolla']?.add(item);
    } else if (name.contains('dip')) {
      groupedItems['Dips']?.add(item);
    } else {
      // Si no coincide con ninguna categoría conocida
      groupedItems['Dips']?.add(item); // Opcional: agregar a "Otros" o "Dips"
    }
  }

  return groupedItems;
}

  Future<void> fetchCarrito() async {
    final url = Uri.parse('$BACKEND_BASE/usuario/${widget.userId}/carrito');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          carritoProductos = List<Map<String, dynamic>>.from(data['carrito']);
        });
      } else {
        print('Error al cargar el carrito: ${response.statusCode}');
      }
    } catch (e) {
      print('Error de conexión al cargar carrito: $e');
    }
  }

  Widget _buildPromoBanner(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
    child: SizedBox(
      height: screenHeight * 0.15,
      width: screenWidth,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(screenWidth * 0.05),
        child: InkWell(
          onTap: () {
  Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PromoScreen(
      userId: widget.userId,
      cartItems: carritoProductos,
      onAddToCart: (promoData, extraQuantities, removedIngredients, bebidaSeleccionada) {
        _addToCarrito(
          {
            'id': promoData['id'],              // id del doc de PROMO
            'name': promoData['name'],
            'price': promoData['price'],
            'imagen': promoData['imagen'],
            'productos': promoData['productos'],
            'bebidas': promoData['bebidas'],
          },
          type: 'promo',
          extraIngredients: extraQuantities,      // ignorado en promo
          removedIngredients: removedIngredients, // ignorado en promo
          bebidaSeleccionada: bebidaSeleccionada, // opcional
        );
      },
    ),
  ),
);
},

          child: Image.asset(
            'assets/promo.jpg',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.fitWidth,
          ),
        ),
      ),
    ),
  );
}


  Widget buildAcompanamientoRow(List<Map<String, dynamic>> acompanamientos) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  return SizedBox(
    height: screenHeight * 0.27, // 🔹 Misma altura que hamburguesas
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: acompanamientos.length,
      itemBuilder: (context, index) {
        final product = acompanamientos[index];

        return GestureDetector(
          onTap: () {}, // Opcional: Puedes agregar acción al tocar el acompañamiento
          child: Container(
            width: screenWidth * 0.38, // 🔹 Igual que hamburguesas
            margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 245, 240, 235), // 🔹 Fondo beige claro
              borderRadius: BorderRadius.circular(screenWidth * 0.05), // Bordes redondeados
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(screenWidth * 0.05)),
                  child: Image.network(
                    product['imagen'] ?? 'https://via.placeholder.com/150',
                    width: double.infinity,
                    height: screenHeight * 0.15, // 🔹 Altura igual que hamburguesas
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.error, size: 50),
                  ),
                ),

                // 🔥 BOTÓN "+" PARA AGREGAR AL CARRITO
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                  child: Align(
                    alignment: Alignment.centerRight, // 🔹 Alineado a la derecha
                    child: GestureDetector(
                      onTap: () {
                        _addToCarrito(product, type: 'acompanamiento');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${product['name']} añadido al carrito.',
                              style: TextStyle(fontSize: screenWidth * 0.04),
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.only(top: screenHeight * 0.005),
                        width: screenWidth * 0.1,
                        height: screenWidth * 0.1,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 233, 73, 25), // 🔹 Naranja fuerte
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: screenWidth * 0.06,
                        ),
                      ),
                    ),
                  ),
                ),

                // 🔥 SECCIÓN NARANJA CON NOMBRE Y PRECIO
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 233, 73, 25),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(screenWidth * 0.05),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03,
                        vertical: screenHeight * 0.008,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                product['name'] ?? 'Sin nombre',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '\$${product['price'] ?? 0}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  fontFamily: 'Poppins',
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

void _addToCarrito(
  Map<String, dynamic> item, {
  required String type,
  Map<String, int>? extraIngredients,
  List<String>? removedIngredients,
  Map<String, dynamic>? bebidaSeleccionada,
}) async {
  String endpoint = '';
  Map<String, dynamic> body = {};

  // Elegir bebida por defecto si el item trae lista
  if (item.containsKey('bebidas') && item['bebidas'] is List) {
    final bebidasList = List<Map<String, dynamic>>.from(item['bebidas']);
    bebidaSeleccionada ??= bebidasList.firstWhere(
      (b) => b['name'].toString().toLowerCase().contains('coca'),
      orElse: () => bebidasList.isNotEmpty ? bebidasList[0] : {},
    );
  }

  if (type == 'hamburguesa') {
    endpoint =
        '$BACKEND_BASE/usuario/${widget.userId}/carrito/hamburguesa?hamburguesa_id=${item['id']}';

    Map<String, dynamic>? beveragePayload;
    if (bebidaSeleccionada != null && bebidaSeleccionada.isNotEmpty) {
      beveragePayload = {
        'name': (bebidaSeleccionada['name'] ?? 'Bebida').toString(),
        'imagen': (bebidaSeleccionada['imagen'] ?? '').toString(), // forzar string
        'quantity': 1,
        'price': 0,
      };
    }

    body = {
      'selected_extras': (extraIngredients?.entries ?? const [])
          .where((e) => e.value > 0)
          .map((e) => {'name': e.key, 'quantity': e.value})
          .toList(),
      'removed_ingredients': removedIngredients ?? [],
      if (beveragePayload != null) 'selected_beverage': beveragePayload,
    };
  } else {
    // type == 'promo'
    endpoint =
        '$BACKEND_BASE/usuario/${widget.userId}/carrito/promo?promo_id=${item['id']}';

    Map<String, dynamic>? beveragePayload;
    if (bebidaSeleccionada != null && bebidaSeleccionada.isNotEmpty) {
      beveragePayload = {
        'name': (bebidaSeleccionada['name'] ?? 'Bebida').toString(),
        'imagen': (bebidaSeleccionada['imagen'] ?? '').toString(),
        'quantity': 1,
        'price': 0,
      };
    }

    body = {
      'cantidad': 1,
      if (beveragePayload != null) 'selected_beverage': beveragePayload,
    };
  }

  debugPrint('📡 POST $endpoint');
  debugPrint('📦 Body: ${json.encode(body)}');

  try {
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    debugPrint('🔍 Status: ${response.statusCode}');
    debugPrint('📬 Resp: ${response.body}');

    if (response.statusCode == 200) {
      fetchCarrito();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añadido al carrito')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar: ${response.statusCode}')),
      );
    }
  } catch (e) {
    debugPrint('❌ Error al conectar: $e');
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 237, 232, 222),
      appBar: _buildAppBar(),
      body: isLoading ? _buildLoadingIndicator() : buildMenuScreen(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Color.fromARGB(255, 237, 232, 222),
      scrolledUnderElevation: 0,
      title: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Image.asset(
              'assets/logomacavi.png',
              width: 60,
              height: 60,
            ),
          ),
          Positioned(
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.shopping_cart, size: 35, color: Color.fromARGB(255, 233, 73, 25)),
              onPressed: _navigateToCarrito,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }

 Widget buildMenuScreen() {
  return SingleChildScrollView(
    physics: const BouncingScrollPhysics(), // Permite desplazamiento suave y evita overflow
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPromoBanner(context), // Banner de promo

        const Text(
          '  ELEGÍ TU BURGER FAV',
          style: TextStyle(
            fontSize: 30,
            fontFamily: 'NewGroteskSquare',
            color: Color.fromARGB(255, 233, 73, 25),
          ),
        ),

        const SizedBox(height: 10),

        // 🔥 Nuevo título "Línea clásica"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: const Text.rich(
            TextSpan(
              text: 'LÍNEA ',
              style: TextStyle(
                fontSize: 22,
                fontFamily: 'NewGroteskSquare',
                color: Color.fromARGB(255, 33, 34, 34),
              ),
              children: [
                TextSpan(
                  text: 'CLÁSICA',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, // Negrita solo en "clásica"
                  ),
                ),
              ],
            ),
          ),
        ),


        if (hamburgers.isNotEmpty)
          buildHamburgerRow(hamburgers.sublist(0, (hamburgers.length / 2).ceil())),

        const SizedBox(height: 20),

// 🔥 Nuevo título "Línea premium"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: const Text.rich(
            TextSpan(
              text: 'LÍNEA ',
              style: TextStyle(
                fontSize: 22,
                fontFamily: 'NewGroteskSquare',
                color: Color.fromARGB(255, 33, 34, 34),
              ),
              children: [
                TextSpan(
                  text: 'PREMIUM',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, // Negrita solo en "clásica"
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        if (hamburgers.length > (hamburgers.length / 2).ceil())
          buildHamburgerRow(hamburgers.sublist((hamburgers.length / 2).ceil())),

        const SizedBox(height: 20),

        PromoCarousel(), // Imagen extra

        const SizedBox(height: 10),

         const Text(
          '  ACOMPAÑAMIENTOS',
          style: TextStyle(
            fontSize: 22,
            fontFamily: 'NewGroteskSquare',
            color: Color.fromARGB(255, 33, 34, 34),
          ),
        ),

        if (acompanamiento.isNotEmpty)
          buildAcompanamientoRow(acompanamiento['Todos los Acompañamientos'] ?? []),


        const SizedBox(height: 20), // Espaciado final para evitar cortes en el scroll
      ],
    ),
  );
}

Widget buildHamburgerRow(List<Map<String, dynamic>> burgers) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  return SizedBox(
    height: screenHeight * 0.27, // Ajuste dinámico de altura para evitar overflow
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: burgers.length,
      itemBuilder: (context, index) {
        final burger = burgers[index];

        return GestureDetector(
          onTap: () => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => BurgerScreen(
      burgerData: burger, // 🔥 Asegúrate de que esto contiene 'bebidas'
      userId: widget.userId,
      onAddToCart: (burgerData, extraIngredients, removedIngredients, bebidaSeleccionada) {
        _addToCarrito(
          burgerData,
          type: 'hamburguesa',
          extraIngredients: extraIngredients,
          removedIngredients: removedIngredients,
          bebidaSeleccionada: bebidaSeleccionada, // ✅ Enviamos la bebida seleccionada
        );
      },
              ),
            ),
          ),
          child: Container(
            width: screenWidth * 0.38, // Ancho ajustado para evitar problemas en pantallas pequeñas
            margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 245, 240, 235), // Fondo beige claro
              borderRadius: BorderRadius.circular(screenWidth * 0.05), // Bordes dinámicos
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen de la hamburguesa
                ClipRRect(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(screenWidth * 0.05)),
                  child: Image.network(
                    burger['imagen'] ?? 'https://via.placeholder.com/150',
                    width: double.infinity,
                    height: screenHeight * 0.15, // Altura dinámica para evitar overflow
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.error, size: 50),
                  ),
                ),

                // 🔥 BOTÓN "+" DENTRO DEL ÁREA BEIGE, JUSTO ANTES DEL NARANJA
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                  child: Align(
                    alignment: Alignment.centerRight, // Alineado a la derecha
                    child: GestureDetector(
                      onTap: () {
  Map<String, dynamic>? bebida;

  if (burger.containsKey('bebidas') && burger['bebidas'] is List) {
    List<Map<String, dynamic>> bebidasList = List<Map<String, dynamic>>.from(burger['bebidas']);

    bebida = bebidasList.firstWhere(
      (b) => b['name'].toString().toLowerCase().contains('coca-cola'),
      orElse: () => bebidasList.isNotEmpty ? bebidasList[0] : {},
    );
  }

  _addToCarrito(
    burger,
    type: 'hamburguesa',
    bebidaSeleccionada: bebida,
  );

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('${burger['name']} añadida al carrito.'),
      duration: Duration(seconds: 1),
    ),
  );
},
                      child: Container(
                        margin: EdgeInsets.only(top: screenHeight * 0.005),
                        width: screenWidth * 0.1,
                        height: screenWidth * 0.1,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 233, 73, 25), // Naranja fuerte
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(2, 2), // Sombra ligera
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: screenWidth * 0.06, // Tamaño adaptable
                        ),
                      ),
                    ),
                  ),
                ),

                // 🔥 SECCIÓN NARANJA CON TEXTO
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 233, 73, 25),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(screenWidth * 0.05),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03,
                        vertical: screenHeight * 0.008,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                burger['name'] ?? 'Sin nombre',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04, // Tamaño adaptable
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '\$${burger['price'] ?? 0}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  fontFamily: 'Poppins',
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget buildFullWidthProductCard(Map<String, dynamic> product) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 8.0),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20), // Bordes circulares
      color: const Color.fromARGB(255, 245, 240, 235), // Fondo beige claro
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          spreadRadius: 2,
          blurRadius: 5,
        ),
      ],
    ),
    width: screenWidth * 0.38, // Ancho del producto para el scroll horizontal
    child: Column(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Image.network(
            product['imagen'] ?? 'https://via.placeholder.com/150',
            height: screenHeight * 0.15,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Container(
          height: screenHeight * 0.10, // Sección naranja
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 233, 73, 25), // 🟠 Naranja predominante
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  product['name'] ?? 'Sin nombre',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '\$${product['price'] ?? 0}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildExtrasRow(List<Map<String, dynamic>> products) {
  final screenHeight = MediaQuery.of(context).size.height;

  return SizedBox(
    height: screenHeight * 0.25, // Altura ajustada para la fila
    child: ListView.builder(
      scrollDirection: Axis.horizontal, // Scroll horizontal
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return buildFullWidthProductCard(product);
      },
    ),
  );
}

Widget _buildBottomNavigationBar() {
  return BottomNavigationBar(
    currentIndex: currentIndex,
    backgroundColor: const Color.fromARGB(255, 233, 73, 25), // Color naranja
    selectedItemColor: Colors.white, // Color del ícono y texto seleccionado
    unselectedItemColor: Colors.white70, // Color del ícono y texto no seleccionado
    items: [
      BottomNavigationBarItem(
        icon: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.fastfood, size: 28), // 🍔 Icono de comida rápida
          ],
        ),
        label: 'Menú',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Perfil',
      ),
    ],
    onTap: (index) {
      setState(() {
        currentIndex = index;
      });

      if (index == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PerfilScreen(
              userId: widget.userId,
              puntosTotales: puntosTotales,
              carritoProductos: carritoProductos,
            ),
          ),
        ).then((_) {
          setState(() {
            currentIndex = 0;
          });
        });
      }
    },
  );
}
}

class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key});

  @override
  _PromoCarouselState createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final List<String> imagePaths = [
    'assets/autentic.jpg',
    'assets/autentic2.jpg'
  ];
  int currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCarousel();
  }

  void _startCarousel() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          currentIndex = (currentIndex + 1) % imagePaths.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // ✅ Cancela el Timer cuando el widget se destruye
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30), // 🔹 Bordes redondeados
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // 🔹 Sombra suave
            blurRadius: 10, // 🔹 Difuminado
            spreadRadius: 2, // 🔹 Tamaño de la sombra
            offset: Offset(3, 5), // 🔹 Posición (derecha y abajo)
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30), // 🔥 Bordes redondeados
        clipBehavior: Clip.antiAlias, 
        child: AspectRatio(
          aspectRatio: 9 / 3, // 🔹 Mantiene la proporción
          child: AnimatedSwitcher( // 🎬 Hace la transición suave al cambiar
            duration: Duration(seconds: 1), // ⏳ Duración de la animación
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation, // Aplica el efecto de difuminado
                child: child,
              );
            },
            child: Image.asset(
              imagePaths[currentIndex],
              key: ValueKey<String>(imagePaths[currentIndex]), // ⚡ Clave única para detectar cambios
              width: double.infinity,
              fit: BoxFit.cover, // 🔹 Evita cortes raros
            ),
          ),
        ),
      ),
    ),
  );
}
}