import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ConfirmarCompraScreen extends StatefulWidget {
  final List<Map<String, dynamic>> carritoProductos;
  final double totalPrice;
  final int totalPoints;
  final Function(Map<String, dynamic>) onAddToCarrito;
  final Function(int) onAddPoints;

  const ConfirmarCompraScreen({
    super.key,
    required this.carritoProductos,
    required this.totalPrice,
    required this.totalPoints,
    required this.onAddToCarrito,
    required this.onAddPoints,
    required String userId,
  });

  @override
  _ConfirmarCompraScreenState createState() => _ConfirmarCompraScreenState();
}

class _ConfirmarCompraScreenState extends State<ConfirmarCompraScreen> {
  String? metodoPago;
  final TextEditingController _calleController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _otraLocalidadController = TextEditingController();
  bool isOtraLocalidadSelected = false;
  String? selectedLocalidad;
  int? precioDelivery;
  List<Map<String, dynamic>> localidades = [];
  bool isLoadingLocalidades = true;
  bool esRetiroLocal = false; // ✅ Nuevo estado para detectar si es retiro en local
  final TextEditingController _nombreRetiroController = TextEditingController();
  String? nombreRetiro;

  @override
  void initState() {
    super.initState();
    _verificarSiYaPago();
    _cargarLocalidades();
  }

  void _verificarSiYaPago() async {
  final prefs = await SharedPreferences.getInstance();
  final pagoEnProceso = prefs.getBool('pago_en_proceso') ?? false;

  if (pagoEnProceso) {
    bool aprobado = await verificarPago();

    if (aprobado && context.mounted) {
      await prefs.setBool('pago_en_proceso', false);

      // 👉 Vaciar carrito automáticamente
      await _vaciarCarritoEnBackend();

      // 👉 Ir directo al menú
      Navigator.pushReplacementNamed(context, '/menu');
    }
  }
}

  Future<void> _vaciarCarritoEnBackend() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('user_id'); // 🔥 Debe estar guardado al hacer login

  if (userId == null) {
    print("⚠️ No se encontró user_id en SharedPreferences");
    return;
  }

  final url = Uri.parse(
    'https://macavi-1049571319674.southamerica-west1.run.app/usuario/$userId/carrito',
  );

  try {
    final response = await http.delete(url);
    if (response.statusCode == 200) {
      print("✅ Carrito vaciado correctamente desde confirmar compra");
    } else {
      print("❌ Error al vaciar el carrito: ${response.body}");
    }
  } catch (e) {
    print("❌ Excepción al vaciar el carrito: $e");
  }
}


  Future<void> _cargarLocalidades() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://macavi-1049571319674.southamerica-west1.run.app/localidades'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          localidades = List<Map<String, dynamic>>.from(data);
          isLoadingLocalidades = false; // Carga completada
        });
      } else {
        throw Exception('Error al obtener localidades: ${response.body}');
      }
    } catch (e) {
      setState(() {
        localidades = [];
        isLoadingLocalidades = false; // Carga completada con error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar localidades: $e')),
      );
    }
  }

Future<String> fetchPreferenceId(List<Map<String, dynamic>> items) async {
  final url = Uri.parse(
      "https://macavi-1049571319674.southamerica-west1.run.app/mercado_pago/crear-preferencia");
  final headers = {"Content-Type": "application/json"};

  SharedPreferences prefs = await SharedPreferences.getInstance();
  final email = prefs.getString('user_email');
  if (email == null || email.isEmpty) {
    throw Exception("No se pudo obtener el email del usuario logueado.");
  }

  // ✅ Guardamos el flag de que el pago está en proceso
  await prefs.setBool('pago_en_proceso', true);

  // ✅ No validar dirección si es retiro en local
  if (esRetiroLocal && _nombreRetiroController.text.isEmpty) {
  throw Exception("Debes ingresar un nombre para retirar.");
}


  // ✅ Construcción del JSON correctamente
  Map<String, dynamic> body = {
    "items": widget.carritoProductos.map((item) {
      return {
        "title": item["name"],
        "quantity": 1,
        "unit_price": item["price"],
        "selectedExtras": (item["selectedExtras"] as List<dynamic>?)?.map((extra) => {
          "name": extra["name"],
          "quantity": extra["quantity"],
          "unit_price": extra.containsKey("unit_price") ? extra["unit_price"] : extra["price"],
        }).toList() ?? [],
        "removedIngredients": item["removedIngredients"] ?? [],

        // ✅ Agregar la bebida si existe
        if (item["selected_beverage"] != null) "selectedBeverage": {
          "name": item["selected_beverage"]["name"],
          "quantity": item["selected_beverage"]["quantity"],
        }
      };
    }).toList(),
    "payer": {
      "email": email
    },
    "costo_delivery": precioDelivery ?? 0 
  };

  // ✅ Agregar dirección solo si NO es retiro en local
  if (!esRetiroLocal) {
    body["direccion"] = {
      "localidad": selectedLocalidad,
      "calle": _calleController.text,
      "numero": _direccionController.text
    };
  } else {
    body["nombre_retiro"] = _nombreRetiroController.text;
  }

  // ✅ Convertir a JSON
  final bodyJson = jsonEncode(body);
  print("📤 JSON enviado a Mercado Pago: $bodyJson");  // Debug para verificar

  // ✅ Enviar la solicitud al backend
  final response = await http.post(url, headers: headers, body: bodyJson);

  if (response.statusCode == 201) {
    final data = jsonDecode(response.body);
    print("✅ init_point: ${data["init_point"]}");
    return data["init_point"];
  } else {
    throw Exception("❌ Error al crear la preferencia: ${response.body}");
  }
}


  void _validarCompra() {
  if (esRetiroLocal) {
    // 🔹 Validar que el usuario haya ingresado su nombre para el retiro
    if (_nombreRetiroController.text.isEmpty) {
      _mostrarAlerta('Debes ingresar un nombre para retirar.');
      return;
    }
  } else {
    // 🔹 Validar que el usuario haya ingresado una localidad válida
    if (selectedLocalidad == null || 
        (selectedLocalidad == 'Otro' && _otraLocalidadController.text.isEmpty)) {
      _mostrarAlerta('Debes seleccionar una localidad válida.');
      return;
    }

    // 🔹 Validar que la calle y el número de dirección estén completos
    if (_calleController.text.isEmpty) {
      _mostrarAlerta('Debes completar la calle.');
      return;
    }

    if (_direccionController.text.isEmpty) {
      _mostrarAlerta('Debes completar el número de dirección.');
      return;
    }
  }

  if (metodoPago == null) {
    _mostrarAlerta('Debes seleccionar un método de pago.');
    return;
  }

  widget.onAddPoints(widget.totalPoints);
  _startPaymentProcess(context);
}


  Future<bool> verificarPago() async {
  final url = Uri.parse("https://macavi-1049571319674.southamerica-west1.run.app/verificar_pago");

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data["status"] == "approved"; // Solo retorna `true` si el pago fue aprobado
  } else {
    return false;
  }
}


  void _startPaymentProcess(BuildContext context) async {
  try {
    final items = widget.carritoProductos.map((producto) {
      return {
        "title": producto["name"],
        "quantity": 1,
        "unit_price": producto["price"],
      };
    }).toList();

    // Obtener la URL del checkout de Mercado Pago
    String initPoint = await fetchPreferenceId(items);

    final uri = Uri.parse(initPoint);
if (await canLaunchUrl(uri)) {
  await launchUrl(uri, mode: LaunchMode.externalApplication); // 🔥 abre en navegador externo
} else {
  throw Exception("No se pudo abrir la URL de Mercado Pago.");
}
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error en el proceso de pago: $error')),
    );
  }
}



  void _mostrarAlerta(String mensaje) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(mensaje),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    resizeToAvoidBottomInset: false, // Evita que el contenido se mueva al abrir el teclado
    appBar: AppBar(
      title: const Text(
        "Confirmar Compra",
        style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
      ),
      backgroundColor: const Color.fromARGB(255, 233, 73, 25),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    body: Container(
      color: const Color.fromARGB(255, 236, 229, 221),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Método de Entrega (Retiro en Local o Envío a domicilio)
                  const Text(
                    "Método de Entrega",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  RadioListTile(
                    title: const Text("Envío a domicilio"),
                    value: false,
                    groupValue: esRetiroLocal,
                    activeColor: Color.fromARGB(255, 233, 73, 25),
                    onChanged: (value) {
                      setState(() {
                        esRetiroLocal = false;
                      });
                    },
                  ),

                  RadioListTile(
                    title: const Text("Retiro en el Local"),
                    value: true,
                    groupValue: esRetiroLocal,
                    activeColor: Color.fromARGB(255, 233, 73, 25),
                    onChanged: (value) {
                      setState(() {
                        esRetiroLocal = true;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  // 🔹 Si elige envío a domicilio, se muestran Localidad y Dirección
                  if (!esRetiroLocal) ...[
                    const Text(
                      "Localidades",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    isLoadingLocalidades
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
  hint: const Text("Seleccionar localidad"),
  value: selectedLocalidad,
  items: localidades.map((localidad) {
    final nombre = localidad['nombre'] ?? 'Desconocido';
    final precio = localidad['precio'] ?? 0;
    return DropdownMenuItem<String>(
      value: nombre,
      child: Text('$nombre - \$${precio.toString()}'),
    );
  }).toList(), // 🔥 Eliminado "Retiro en el local"
  onChanged: (value) {
    setState(() {
      selectedLocalidad = value;
      isOtraLocalidadSelected = value == 'Otro';
      precioDelivery = localidades.firstWhere(
        (localidad) => localidad['nombre'] == value,
        orElse: () => {'precio': 0},
      )['precio'];
    });
  },
),

                    if (isOtraLocalidadSelected)
                      TextField(
                        controller: _otraLocalidadController,
                        decoration: const InputDecoration(labelText: 'Otra Localidad'),
                      ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: _calleController,
                      decoration: const InputDecoration(labelText: 'Calle'),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: _direccionController,
                      decoration: const InputDecoration(labelText: 'Número de Dirección'),
                    ),
                  ],

                  // 🔹 Si elige Retiro en el Local, se muestra solo el campo de Nombre
                  if (esRetiroLocal)
                    TextField(
                      controller: _nombreRetiroController, // ✅ Usa el controlador
                      decoration: const InputDecoration(labelText: 'Nombre para retirar'),
                    ),

                  const SizedBox(height: 20),

                  if (!esRetiroLocal && precioDelivery != null)
                    Text(
                      'Precio del delivery: \$${precioDelivery?.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16),
                    ),

                  const SizedBox(height: 20),

                  // 🔹 Método de Pago
                  const Text(
                    "Método de Pago",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  RadioListTile(
                    title: const Text("Mercado Pago"),
                    value: "mercado_pago",
                    groupValue: metodoPago,
                    activeColor: const Color.fromARGB(255, 233, 73, 25),
                    onChanged: (value) {
                      setState(() {
                        metodoPago = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // 🔹 Botón de Confirmar Compra
          SafeArea(
            child: Container(
              color: const Color.fromARGB(255, 236, 229, 221),
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _validarCompra,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: const Color.fromARGB(255, 233, 73, 25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Confirmar Compra',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

}
