import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ShopScreen extends StatefulWidget {
  final int puntosTotales;

  const ShopScreen({super.key, required this.puntosTotales});

  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late int puntosRestantes;

  @override
  void initState() {
    super.initState();
    puntosRestantes = widget.puntosTotales; // Inicializamos los puntos totales
  }

  Future<void> canjearPremio(String premio, int costo) async {
    if (puntosRestantes >= costo) {
      final url = Uri.parse('https://macavi-1049571319674.southamerica-west1.run.app/canjear');

      final response = await http.post(url, body: {
        'premio': premio,
        'costo': costo.toString(),
        'puntosRestantes': puntosRestantes.toString(),
      });

      if (response.statusCode == 200) {
        setState(() {
          puntosRestantes -= costo;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Premio canjeado exitosamente!'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al canjear el premio.'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes suficientes puntos.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 236, 229, 221),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'MACAVI SHOP',
          style: TextStyle(
            fontFamily: 'NewGroteskSquare',
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset(
              'assets/M.png',
              width: 50,
              height: 50,
            ),
          ),
        ],
        backgroundColor: const Color.fromARGB(255, 233, 73, 25),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tienes $puntosRestantes McvPoints',
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Poppins',
                color: Color.fromARGB(255, 233, 73, 25),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Premios disponibles:',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Poppins',
                color: Color.fromARGB(255, 33, 34, 34),
              ),
            ),
            const SizedBox(height: 20),
            buildPremioOption('Cono de papa', 50),
            buildPremioOption('Dip de cheddar', 30),
            buildPremioOption('Hamburguesa free', 100),
          ],
        ),
      ),
    );
  }

  Widget buildPremioOption(String premio, int costo) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 5,
      child: ListTile(
        leading: const Icon(
          Icons.card_giftcard,
          color: Color.fromARGB(255, 233, 73, 25),
          size: 30,
        ),
        title: Text(
          premio,
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'Poppins',
            color: Color.fromARGB(255, 33, 34, 34),
          ),
        ),
        subtitle: Text(
          'Costo: $costo puntos',
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Poppins',
            color: Colors.grey,
          ),
        ),
        trailing: ElevatedButton(
          onPressed: () => canjearPremio(premio, costo),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 233, 73, 25),
          ),
          child: const Text(
            'Canjear',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
