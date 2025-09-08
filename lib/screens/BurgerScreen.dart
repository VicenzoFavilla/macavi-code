import 'dart:convert';

import 'package:flutter/material.dart';

class BurgerScreen extends StatefulWidget {
  final Map<String, dynamic> burgerData;
  final String userId;
  final void Function(Map<String, dynamic>, Map<String, int>, List<String>, Map<String, dynamic>?) onAddToCart;


  const BurgerScreen({
    super.key,
    required this.burgerData,
    required this.userId,
    required this.onAddToCart,
  });

  @override
  _BurgerScreenState createState() => _BurgerScreenState();
}

class _BurgerScreenState extends State<BurgerScreen> {
  bool isVeggie = false;
  Map<String, int> extraQuantities = {};
  Map<String, bool> editableIngredients = {};
  List<String> removedIngredients = [];
  List<Map<String, dynamic>> bebidas = []; // 🔥 Agrega esta lista para las bebidas
  bool isBeverageMenuOpen = false; // 🔹 Estado del menú de bebidas (abierto o cerrado)
  Map<String, dynamic>? bebidaSeleccionada; // 🔹 Bebida seleccionada
  bool isExtrasMenuOpen = false; // Estado para el menú de extras

 @override
void initState() {
  super.initState();

  print("🔍 Datos en BurgerScreen: ${jsonEncode(widget.burgerData)}"); // 🔥 Verifica en consola que bebidas están presentes

  isVeggie = widget.burgerData['veggie'] ?? false;

  if (widget.burgerData['extraingredients'] != null) {
    for (var extra in widget.burgerData['extraingredients']) {
      extraQuantities[extra['name']] = 0;
    }
  }

  if (widget.burgerData['ingredients'] != null) {
    for (var ingredient in widget.burgerData['ingredients']) {
      editableIngredients[ingredient] = true;
    }
  }

  if (widget.burgerData.containsKey('bebidas') && widget.burgerData['bebidas'] is List) {
    bebidas = List<Map<String, dynamic>>.from(widget.burgerData['bebidas']);

    // ✅ Seleccionar Coca-Cola como predeterminada si está en la lista
    bebidaSeleccionada = bebidas.firstWhere(
  (bebida) => bebida['name'].toString().toLowerCase().contains('coca-cola'),
  orElse: () => bebidas.isNotEmpty ? Map<String, dynamic>.from(bebidas[0]) : {},
);

  }

  print("📌 Bebida seleccionada por defecto: ${jsonEncode(bebidaSeleccionada)}");
}


  int _calculateTotalPrice() {
  final basePrice = (widget.burgerData['price'] is int)
      ? (widget.burgerData['price'] as int).toDouble()
      : widget.burgerData['price'] as double;

  final extrasPrice = extraQuantities.entries.fold(0.0, (sum, entry) {
    final extra = widget.burgerData['extraingredients']
        ?.firstWhere((e) => e['name'] == entry.key, orElse: () => null);
    if (extra != null) {
      final extraPrice = (extra['price'] is int)
          ? (extra['price'] as int).toDouble()
          : extra['price'] as double;
      return sum + (extraPrice * entry.value);
    }
    return sum;
  });

  // Retorna el precio total como un entero redondeado
  return (basePrice + extrasPrice).toInt();
}

  int _calculatePoints() {
    return (_calculateTotalPrice() / 100).floor();
  }

  Widget _buildExtraIngredientsSelector() {
  print("📌 Bebidas en burgerData al construir el selector: ${jsonEncode(bebidas)}");

  final extraIngredients = widget.burgerData['extraingredients'] ?? [];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 🔹 Sección de ingredientes extra
      if (extraIngredients.isNotEmpty) 

      // 🔥 Agregar el menú de extras similar al de bebidas
GestureDetector(
  onTap: () {
    setState(() {
      isExtrasMenuOpen = !isExtrasMenuOpen;
      print("📌 Estado del menú de extras: $isExtrasMenuOpen");
    });
  },
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Elige tus extras:',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: "Poppins",color: Colors.white),
      ),
      Icon(
        isExtrasMenuOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
        color: Colors.white,
        size: 30,
      ),
    ],
  ),
),

if (isExtrasMenuOpen)
  Column(
    children: widget.burgerData['extraingredients'].map<Widget>((extra) {
      final extraName = extra['name'];
      final extraPrice = extra['price'] ?? 0;
      final quantity = extraQuantities[extraName] ?? 0;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$extraName (\$$extraPrice)',
              style: const TextStyle(fontSize: 16, fontFamily: "Aktiv",color: Colors.white),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (quantity > 0) {
                      setState(() {
                        extraQuantities[extraName] = quantity - 1;
                      });
                    }
                  },
                  icon: const Icon(Icons.remove, color: Colors.white),
                ),
                Text(
                  '$quantity',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      extraQuantities[extraName] = quantity + 1;
                    });
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList(),
  ),

      const SizedBox(height: 16), 

      // 🔹 Sección de bebidas
      if (bebidas.isNotEmpty) ...[
        GestureDetector(
          onTap: () {
            setState(() {
              isBeverageMenuOpen = !isBeverageMenuOpen;
              print("📌 Estado del menú de bebidas: $isBeverageMenuOpen");
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Elige tu bebida:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: "Poppins" ,color: Colors.white),
              ),
              Icon(
                isBeverageMenuOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 30,
              ),
            ],
          ),
        ),

        if (isBeverageMenuOpen)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: bebidas.length,
              itemBuilder: (context, index) {
                final bebida = bebidas[index];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      bebidaSeleccionada = Map<String, dynamic>.from(bebida);
                    });
                  },
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: bebidaSeleccionada != null && bebidaSeleccionada!['name'] == bebida['name']
                          ? Color.fromARGB(255, 236, 229, 221)
                          : Color.fromARGB(255, 233, 73, 25),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          bebida['imagen'] ?? 'https://via.placeholder.com/100',
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.error, color: Colors.red);
                          },
                        ),
                        const SizedBox(height: 5),
                        Text(
                          bebida['name'] ?? "Bebida",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, fontFamily: "Aktiv",color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    ],
  );
}

Widget _buildExtraItem(Map<String, dynamic> extra) {
  final extraName = extra['name'];
  final extraPrice = (extra['price'] is int)
      ? (extra['price'] as int).toDouble()
      : extra['price'] as double;
  final quantity = extraQuantities[extraName] ?? 0;

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // Nombre del extra
      Text(
        '$extraName (\$$extraPrice)',
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),

      // Controles de cantidad (+ / -)
      Row(
        children: [
          IconButton(
            onPressed: () {
              if (quantity > 0) {
                setState(() {
                  extraQuantities[extraName] = quantity - 1;
                });
              }
            },
            icon: const Icon(Icons.remove, color: Colors.white),
          ),
          Text(
            '$quantity',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                extraQuantities[extraName] = quantity + 1;
              });
            },
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    ],
  );
}


  Widget _buildSelectedIngredients() {
  final selectedIngredients = editableIngredients.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key)
      .toList();

  return Text(
    selectedIngredients.isNotEmpty
        ? selectedIngredients.join(", ") // Une los ingredientes con comas
        : "Sin ingredientes seleccionados", // Mensaje si no hay ingredientes
    style: const TextStyle(
      fontSize: 16,
      fontFamily: "Aktiv",
      color: Colors.white, // Texto en color blanco
    ),
  );
}


  Widget _buildBottomSection(MediaQueryData mediaQuery) {
  return Container(
    padding: const EdgeInsets.all(16.0),
    decoration: const BoxDecoration(
      color: Color.fromARGB(255, 233, 73, 25), // 🔸 Fondo naranja
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(40),
        topRight: Radius.circular(40),
      ),
    ),
    child: Column(
      children: [
        // 🔹 Fila con Precio Total y Editar Ingredientes
        Row(
          children: [
            // Precio Total (ajustable al espacio disponible)
            Expanded(
              flex: 2, // Más espacio para el precio
              child: Text(
                'Precio Total: \$${_calculateTotalPrice()}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Poppins",
                  color: Colors.white,
                ),
              ),
            ),

            // Botón Editar Ingredientes (ajustable)
            Expanded(
              flex: 1, // Menos espacio para el botón
              child: OutlinedButton(
                onPressed: _showEditIngredientsDialog,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Editar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 233, 73, 25),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        ElevatedButton.icon(
  onPressed: _addToCart,
  icon: const Icon(
    Icons.shopping_cart, // Icono de carrito
    color: Color.fromARGB(255, 233, 73, 25), // Color naranja
  ),
  label: const Text(
    'Añadir al carrito',
    style: TextStyle(
      fontSize: 20,
      fontFamily: "NewGroteskSquare",
      color: Color.fromARGB(255, 233, 73, 25), // Texto en color naranja
    ),
  ),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.white, // Fondo blanco
    padding: const EdgeInsets.symmetric(vertical: 16.0),
    minimumSize: const Size(double.infinity, 50), // Ancho completo
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),
),

      ],
    ),
  );
}

 void _showEditIngredientsDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Editar'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: editableIngredients.keys
                  .where((ingredient) =>
                      ingredient != "Doble Medallon" && ingredient != "Doble Pollo")
                  .map((ingredient) {
                return CheckboxListTile(
                  title: Text(ingredient),
                  value: editableIngredients[ingredient],
                  activeColor: const Color.fromARGB(255, 233, 73, 25),
                  onChanged: (bool? value) {
                    setDialogState(() {
                      editableIngredients[ingredient] = value ?? true;

                      if (!value!) {
                        // Agrega a `removedIngredients` si desmarcado.
                        if (!removedIngredients.contains(ingredient)) {
                          removedIngredients.add(ingredient);
                        }
                      } else {
                        // Remueve de `removedIngredients` si marcado.
                        removedIngredients.remove(ingredient);
                      }
                    });

                    // Actualiza el estado principal.
                    setState(() {});
                  },
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 233, 73, 25),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

void _addToCart() {
  print("🟢 Agregando al carrito: bebidaSeleccionada = $bebidaSeleccionada");

  final Map<String, dynamic> item = {
    'id': widget.burgerData['id'],
    'name': widget.burgerData['name'],
    'price': _calculateTotalPrice(),
    'points': _calculatePoints(),
    'veggie': isVeggie,
    'ingredients': editableIngredients.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList(),
    'selectedExtras': extraQuantities.entries
        .where((entry) => entry.value > 0)
        .map((entry) => {
              'name': entry.key,
              'price': widget.burgerData['extraingredients']
                  ?.firstWhere((e) => e['name'] == entry.key, orElse: () => {'price': 0})['price'],
              'quantity': entry.value,
            })
        .toList(),
    'removedIngredients': removedIngredients,
  };

  // ✅ Agregar la bebida seleccionada si existe
  if (bebidaSeleccionada != null) {
    item['selected_beverage'] = {
      'name': bebidaSeleccionada?['name'] ?? 'Sin nombre',
      'imagen': bebidaSeleccionada?['imagen'] ?? '',
      'quantity': 1,
    };
  }

  print("🛒 JSON enviado al carrito: ${jsonEncode(item)}");

  widget.onAddToCart(item, extraQuantities, removedIngredients, bebidaSeleccionada);

  Navigator.pop(context);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('${widget.burgerData['name']} añadida al carrito'),
      duration: const Duration(seconds: 1),
    ),
  );
}




  @override
Widget build(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);

  return Scaffold(
  appBar: AppBar(
    automaticallyImplyLeading: false,
    backgroundColor: Color.fromARGB(255, 237, 232, 222), // ✅ Color fijo
    elevation: 0, // ✅ Evita sombras
    scrolledUnderElevation: 0, // ✅ Evita cambios de color al hacer scroll
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 233, 73, 25)),
      onPressed: () => Navigator.pop(context),
    ),
    title: Stack(
      children: [
        Align(
          alignment: Alignment.center,
          child: Transform.translate(
            offset: const Offset(-30, 0), // Ajuste fino para centrar la imagen
            child: Image.asset(
              'assets/logomacavi.png',
              width: 60,
              height: 60,
            ),
          ),
        ),
      ],
    ),
  ),

    backgroundColor: const Color.fromARGB(255, 236, 229, 221), // Fondo general crema
    body: Column(
      children: [
        // Imagen de la hamburguesa con fondo crema
        Container(
          height: mediaQuery.size.height * 0.45, // Ajuste dinámico de la imagen
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 236, 229, 221), // Fondo crema
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          alignment: Alignment.center,
          child: Container(
            height: mediaQuery.size.height * 0.90, // Imagen más grande
            width: mediaQuery.size.width * 1, // Ajuste dinámico del ancho
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 236, 229, 221), // Fondo crema
              borderRadius: BorderRadius.circular(30),
              image: DecorationImage(
                image: NetworkImage(widget.burgerData['imagen']),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        // Contenido dentro del fondo naranja
Expanded(
  child: Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      color: Color.fromARGB(255, 233, 73, 25), // Fondo naranja
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(40),
        topRight: Radius.circular(40),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Aquí agregamos el nombre y el precio juntos en una fila
            Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    // Nombre de la hamburguesa (en mayúsculas)
    Expanded(
      child: Text(
  (widget.burgerData['name'] ?? "BURGER").toUpperCase(),
  style: const TextStyle(
    fontSize: 35,
    fontWeight: FontWeight.bold,
    fontFamily: 'NewGroteskSquare', // 🔹 Fuente para títulos
    color: Colors.white,
  ),
),
    ),

    // Precio al lado del nombre (sin decimales)
    Text(
  '\$${_calculateTotalPrice()}',
  style: const TextStyle(
    fontSize: 35,
    fontWeight: FontWeight.bold,
    fontFamily: 'Poppins', // 🔹 Fuente para precios
    color: Colors.white,
  ),
),
  ],
),


            // Ingredientes seleccionados
            const Text(
  'Ingredientes:',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    fontFamily: 'Poppins', // 🔹 Fuente para secciones
    color: Colors.white,
  ),
),
            const SizedBox(height: 8),
            _buildSelectedIngredients(),

            const SizedBox(height: 16),
            const Text(
  'Selecciona ingredientes:',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    fontFamily: 'Poppins',
    color: Colors.white,
  ),
),
            const SizedBox(height: 10),
            _buildExtraIngredientsSelector(),

            const SizedBox(height: 20),

            // Botones en la parte inferior
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildBottomSection(mediaQuery),
            ),
          ],
        ),
      ),
    ),
  ),
),

      ],
    ),
  );
}

}
