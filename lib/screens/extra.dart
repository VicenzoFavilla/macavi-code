import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dots_indicator/dots_indicator.dart';

class ExtraScreen extends StatefulWidget {
  final void Function(Map<String, dynamic> burgerData, Map<String, int> extraIngredients) onAddToCart;

  final List<Map<String, dynamic>> carritoProductos;
  
  final dynamic onAddToCarrito;

  const ExtraScreen({super.key, 
    required this.onAddToCarrito,
    required this.carritoProductos, required this.onAddToCart,
  });

  @override
  _ExtraScreenState createState() => _ExtraScreenState();
}

class _ExtraScreenState extends State<ExtraScreen> {
  List<Map<String, dynamic>> bebidas = [];
  List<Map<String, dynamic>> acompanamientos = [];

  @override
  void initState() {
    super.initState();
    fetchAcompanamientos();
    fetchBebidas();
  }

  // Método para obtener acompañamientos desde la API
  Future<void> fetchAcompanamientos() async {
    final url = Uri.parse('https://macavi-1049571319674.southamerica-west1.run.app/extra');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          acompanamientos = data.map((item) {
            return {
              'name': item['name'],
              'price': item['price'],
              'image': item['image'],
            };
          }).toList();
        });
      } else {
        throw Exception('Error al cargar los acompañamientos');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Método para obtener bebidas desde la API
  Future<void> fetchBebidas() async {
    final url = Uri.parse('https://macavi-1049571319674.southamerica-west1.run.app/bebidas');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          bebidas = data.map((item) {
            return {
              'name': item['name'],
              'variants': item['variants'],
            };
          }).toList();
        });
      } else {
        throw Exception('Error al cargar las bebidas');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _addToCarrito(BuildContext context, Map<String, dynamic> variant) {
    final newItem = {
      'name': variant['name'] ?? 'Sin nombre',
      'price': variant['price'] ?? '\$0',
      'image': variant['image'] ?? '',
      'quantity': 1,
      'category': 'Acompañamiento',
    };

    widget.onAddToCarrito(newItem);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Añadiste ${variant['name']} al carrito'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 236, 229, 221),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 0),
              _buildSectionTitle('Acompañamientos'),
              const SizedBox(height: 5),
              ...acompanamientos.map((item) => _buildItem(context, item)),
              const SizedBox(height: 20),
              _buildSectionTitle('Bebidas'),
              const SizedBox(height: 5),
              ...bebidas.map((item) => _buildDrinkItem(context, item)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 30,
        fontFamily: 'NewGroteskSquare',
        color: Color.fromARGB(255, 33, 34, 34),
      ),
    );
  }

  Widget _buildItem(BuildContext context, Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 5,
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  item['image'] ?? '',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item['name'] ?? 'Sin nombre',
                    style: const TextStyle(
                      fontSize: 20,
                      fontFamily: 'Poppins',
                      color: Color.fromARGB(255, 33, 34, 34),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['price'] ?? '',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Poppins',
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _addToCarrito(context, item),
              icon: const Icon(Icons.add_shopping_cart, size: 30, color: Color.fromARGB(255, 233, 73, 25)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrinkItem(BuildContext context, Map<String, dynamic> drink) {
    final PageController controller = PageController();
    int currentPage = 0;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Column(
          children: [
            SizedBox(
              height: 110,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: controller,
                    itemCount: drink['variants'].length,
                    onPageChanged: (index) {
                      setState(() {
                        currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final variant = drink['variants'][index];
                      return _buildItem(context, {
                        'name': '${drink['name']} ${variant['size']}',
                        'price': variant['price'],
                        'image': variant['image'],
                      });
                    },
                  ),
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: DotsIndicator(
                        dotsCount: drink['variants'].length,
                        position: currentPage.toDouble(),
                        decorator: DotsDecorator(
                          activeColor: const Color.fromARGB(255, 233, 73, 25),
                          size: const Size.square(8.0),
                          activeSize: const Size(10.0, 10.0),
                          activeShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
