import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:macavi/screens/perfil.dart';

class PromoScreen extends StatefulWidget {
  final String userId;
  final List<Map<String, dynamic>> cartItems;

  /// MISMA FIRMA QUE EN BurgerScreen
  final void Function(
    Map<String, dynamic>,     // item (promo)
    Map<String, int>,         // extraQuantities (no se usa en promo)
    List<String>,             // removedIngredients (no se usa en promo)
    Map<String, dynamic>?,    // selectedBeverage (opcional)
  ) onAddToCart;

  const PromoScreen({
    super.key,
    required this.userId,
    required this.cartItems,
    required this.onAddToCart,
  });

  @override
  State<PromoScreen> createState() => _PromoScreenState();
}

class _PromoScreenState extends State<PromoScreen> {
  int currentIndex = 0;
  bool loading = true;
  List<Map<String, dynamic>> promos = [];
  // selección por promoId -> bebida seleccionada
  final Map<String, Map<String, dynamic>?> _bebidaSelByPromo = {};

  static const String _BASE = 'https://macavi-backend-1049571319674.southamerica-west1.run.app';

  @override
  void initState() {
    super.initState();
    _fetchPromos();
  }

  Future<void> _fetchPromos() async {
    try {
      final resp = await http.get(Uri.parse("$_BASE/promos"));
      if (resp.statusCode == 200) {
        final List data = json.decode(resp.body);
        setState(() {
          promos = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();

          // inicializa bebida seleccionada (si hay), prioriza Coca; si no hay imagen, no la mandamos luego
          for (final p in promos) {
            final bebidas = (p['bebidas'] is List)
                ? List<Map<String, dynamic>>.from(p['bebidas'])
                : <Map<String, dynamic>>[];

            Map<String, dynamic>? pre;
            if (bebidas.isNotEmpty) {
              pre = bebidas.firstWhere(
                (b) => (b['name'] ?? '').toString().toLowerCase().contains('coca'),
                orElse: () => bebidas.first,
              );
            }
            _bebidaSelByPromo[p['id'].toString()] = pre;
          }

          loading = false;
        });
      } else {
        loading = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar promos: ${resp.statusCode}')),
          );
        }
      }
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudieron cargar las promos')),
        );
      }
    }
  }

  void _addPromo(Map<String, dynamic> promo) {
    final String promoId = promo['id'].toString();
    final bebidaSel = _bebidaSelByPromo[promoId];

    // Sanitizar bebida: si no hay imagen válida, no la enviamos
    Map<String, dynamic>? bebidaPayload;
    if (bebidaSel != null) {
      final img = (bebidaSel['imagen'] ?? '').toString().trim();
      if (img.isNotEmpty) {
        bebidaPayload = {
          'name': (bebidaSel['name'] ?? 'Bebida').toString(),
          'imagen': img,
          'quantity': 1,
          'price': 0,
        };
      }
    }

    final item = <String, dynamic>{
      'id': promoId,                             // id del doc de PROMO
      'name': (promo['name'] ?? 'Promo').toString(),
      'price': promo['price'] ?? 0,
      'imagen': (promo['imagen'] ?? '').toString(),
      'productos': promo['productos'],           // opcional
      'bebidas': promo['bebidas'],               // opcional
    };

    widget.onAddToCart(
      item,
      <String, int>{}, // extras vacíos (no aplica a promo)
      <String>[],      // removidos vacíos (no aplica a promo)
      bebidaPayload,   // bebida opcional saneada
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item["name"]} añadida al carrito')),
      );
    }
  }

  BottomNavigationBar _bottomBar() {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      backgroundColor: const Color.fromARGB(255, 233, 73, 25),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.fastfood, size: 28), label: 'Menú'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ],
      onTap: (i) {
        setState(() => currentIndex = i);
        if (i == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PerfilScreen(
                userId: widget.userId,
                puntosTotales: 0,
                carritoProductos: widget.cartItems,
              ),
            ),
          ).then((_) => mounted ? setState(() => currentIndex = 0) : null);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      bottomNavigationBar: _bottomBar(),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 233, 73, 25),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Image.asset('assets/M.png', width: 50, height: 50),
          ],
        ),
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(screenW * 0.03),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: promos.map((promo) {
                    final promoId = promo['id'].toString();
                    final bebidas = (promo['bebidas'] is List)
                        ? List<Map<String, dynamic>>.from(promo['bebidas'])
                        : <Map<String, dynamic>>[];
                    final productos = (promo['productos'] is List)
                        ? List<Map<String, dynamic>>.from(promo['productos'])
                        : <Map<String, dynamic>>[];

                    final bebidaSel = _bebidaSelByPromo[promoId];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 245, 240, 235),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // título + precio
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      promo["name"] ?? "Promo",
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'NewGroteskSquare',
                                        color: Color.fromARGB(255, 33, 34, 34),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '\$${promo["price"] ?? 0}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                      color: Color.fromARGB(255, 233, 73, 25),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // imagen
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  (promo["imagen"] ?? '').toString(),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 160,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox(height: 160, child: Center(child: Icon(Icons.broken_image))),
                                ),
                              ),

                              // productos (si hay)
                              if (productos.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                const Text(
                                  'Incluye:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: productos.map((p) {
                                    final nombre = (p['name'] ?? '').toString();
                                    final tipo = (p['tipo'] ?? '').toString();
                                    final cant = (p['cantidad'] ?? 1).toString();
                                    final chip = nombre.isEmpty ? 'Producto' : nombre;
                                    return Chip(
                                      label: Text('$chip x$cant${tipo.isNotEmpty ? ' • $tipo' : ''}'),
                                      backgroundColor: const Color.fromARGB(255, 236, 229, 221),
                                    );
                                  }).toList(),
                                ),
                              ],

                              // bebidas (si hay)
                              if (bebidas.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                const Text(
                                  'Bebida (opcional):',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  height: 100,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: bebidas.length,
                                    itemBuilder: (context, i) {
                                      final b = bebidas[i];
                                      final selected = (bebidaSel != null) &&
                                          (bebidaSel['name']?.toString() == b['name']?.toString());
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _bebidaSelByPromo[promoId] = b;
                                          });
                                        },
                                        child: Container(
                                          width: 110,
                                          margin: const EdgeInsets.only(right: 8),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? const Color.fromARGB(255, 233, 73, 25)
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: const Color.fromARGB(255, 233, 73, 25),
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Image.network(
                                                  (b['imagen'] ?? '').toString(),
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (_, __, ___) =>
                                                      const Icon(Icons.local_drink),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                (b['name'] ?? 'Bebida').toString(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: selected ? Colors.white : Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],

                              const SizedBox(height: 10),

                              // botón agregar
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 233, 73, 25),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => _addPromo(promo),
                                  child: const Text(
                                    "Agregar al carrito",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
      ),
    );
  }
}
