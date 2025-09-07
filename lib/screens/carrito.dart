import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// 📌 Para manejar fechas y horas
import 'confirm_compra.dart';


const String BASE = 'https://macavi-backend-1049571319674.southamerica-west1.run.app';


class CarritoScreen extends StatefulWidget {
  final String userId;

  const CarritoScreen({
    super.key,
    required this.userId,
  });

  @override
  _CarritoScreenState createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  List<Map<String, dynamic>> carritoProductos = [];
  double totalPrice = 0.0;
  int totalPoints = 0;
  bool isLoading = true;
  bool isButtonEnabled = false; // Estado del botón (true = activo, false = desactivado)

  void _checkHorario() {
  DateTime now = DateTime.now();
  int hora = now.hour;
  int diaSemana = now.weekday; // Lunes = 1, Domingo = 7

  // Solo activar si es Miércoles (3) a Domingo (7) y entre 20 y 23 hs
  bool permitido = (diaSemana >= 3 && diaSemana <= 7) && (hora >= 13 && hora < 23);

  setState(() {
    isButtonEnabled = permitido;
  });

  print("📅 Día: $diaSemana | ⏰ Hora: $hora | Botón activo: $isButtonEnabled");
}

  @override
  void initState() {
  super.initState();
  fetchCarritoProductos();
  _checkHorario(); // 📌 Verificar horario cuando se carga la pantalla
}

  Future<void> fetchCarritoProductos() async {
    final url = Uri.parse('$BASE/usuario/${widget.userId}/carrito');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          carritoProductos = List<Map<String, dynamic>>.from(data['carrito']);
          totalPrice = carritoProductos.fold(
              0.0, (sum, item) => sum + (item['price'] ?? 0.0));
          totalPoints = carritoProductos.fold(0, (sum, item) {
            final points = item['points'];
            if (points is int) return sum + points;
            if (points is double) return sum + points.toInt();
            return sum;
          });
          isLoading = false;
        });

        print("🛒 Carrito cargado: ${jsonEncode(carritoProductos)}"); // Debug
      } else {
        showError('Error al cargar el carrito: ${response.reasonPhrase}');
      }
    } catch (e) {
      showError('Error al conectar con el servidor');
    }
  }

  Future<void> _vaciarCarrito() async {
  final url = Uri.parse('$BASE/usuario/${widget.userId}/carrito');

  try {
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      print("✅ Carrito vaciado correctamente");
    } else {
      showError("No se pudo vaciar el carrito");
    }
  } catch (e) {
    showError("Error al intentar vaciar el carrito");
  }
}

  Future<void> removeProductoFromCarrito(String uniqueId) async {
    final url = Uri.parse(
        '$BASE/usuario/${widget.userId}/carrito/$uniqueId');
    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        fetchCarritoProductos();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto eliminado del carrito'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        showError('No se pudo eliminar el producto');
      }
    } catch (e) {
      showError('Excepción al intentar eliminar el producto');
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _confirmarCompra() async {
  final resultado = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ConfirmarCompraScreen(
        carritoProductos: carritoProductos,
        totalPrice: totalPrice,
        totalPoints: totalPoints,
        onAddToCarrito: (producto) {
          setState(() {
            carritoProductos.add(producto);
          });
        },
        onAddPoints: (points) {
          setState(() {
            totalPoints += points;
          });
        },
        userId: widget.userId,
      ),
    ),
  );

  // 🚨 Verifica si ConfirmarCompraScreen devolvió `true`
  if (resultado == true) {
    await _vaciarCarrito();       // Borra el carrito en el backend
    await fetchCarritoProductos(); // Refresca la lista local
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 237, 232, 222),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : carritoProductos.isEmpty
              ? const Center(
                  child: Text(
                    'El carrito está vacío',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: carritoProductos.length,
                        itemBuilder: (context, index) {
                          final producto = carritoProductos[index];
                          final removedIngredients =
                              producto['removedIngredients'] ?? [];
                          final selectedExtras =
                              producto['selectedExtras'] ?? [];
                          final selectedBeverage =
                              producto['selectedBeverage'] ?? producto['selected_beverage'];

                          return Card(
                            margin: const EdgeInsets.all(8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 4,
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: producto['imagen'] != null
                                    ? Image.network(
                                        producto['imagen'],
                                        fit: BoxFit.cover,
                                        width: 70,
                                        height: 70,
                                      )
                                    : const Icon(Icons.fastfood, size: 50),
                              ),
                              title: Text(
                                producto['name'] ?? 'Producto',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Precio: \$${producto['price']}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  // Mostrar bebida seleccionada (solo si tiene al menos name o imagen)
if (selectedBeverage != null &&
    (((selectedBeverage['name'] ?? '').toString().trim().isNotEmpty) ||
     ((selectedBeverage['imagen'] ?? '').toString().trim().isNotEmpty)))
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Bebida:',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              (selectedBeverage['imagen'] ?? '').toString().trim().isNotEmpty
                  ? selectedBeverage['imagen']
                  : 'https://via.placeholder.com/50',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.local_drink, size: 40),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            (selectedBeverage['name'] ?? 'Bebida').toString(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          if ((selectedBeverage['quantity'] ?? 0) != 0) ...[
            const SizedBox(width: 6),
            Text('x${selectedBeverage['quantity']}',
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ],
        ],
      ),
    ],
  ),
                                  // Mostrar extras seleccionados
                                  if (selectedExtras.isNotEmpty)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children:
                                          selectedExtras.map<Widget>((extra) {
                                        return Text(
                                          'Con: ${extra['name']} x${extra['quantity']}',
                                          style: const TextStyle(
                                              fontSize: 14, color: Colors.grey),
                                        );
                                      }).toList(),
                                    ),
                                  // Mostrar ingredientes removidos
                                  if (removedIngredients.isNotEmpty)
                                    Text(
                                      'Sin: ${removedIngredients.join(", ")}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.red,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => removeProductoFromCarrito(
                                    producto['unique_id']),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 236, 229, 221),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey,
                            offset: Offset(0, -1),
                            blurRadius: 6.0,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Total: \$${totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
  onPressed: isButtonEnabled ? _confirmarCompra : null, // ⛔ Deshabilitado fuera del horario
  style: ElevatedButton.styleFrom(
    backgroundColor: isButtonEnabled
        ? const Color.fromARGB(255, 233, 73, 25) // ✅ Color normal si está activo
        : Colors.grey, // ⛔ Color gris si está deshabilitado
    padding: const EdgeInsets.symmetric(vertical: 16.0),
    minimumSize: Size(MediaQuery.of(context).size.width, 50),
  ),
  child: Text(
    isButtonEnabled ? 'Confirmar Compra' : 'Disponible Miercoles a Domingo de 20:00 a 23:00hs',
    style: const TextStyle(fontSize: 18, color: Colors.white),
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
