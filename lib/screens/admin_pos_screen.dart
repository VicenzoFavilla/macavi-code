import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // solo para guardar pedidos
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'perfil.dart';
import 'package:http/http.dart' as http;

class AdminPOSScreen extends StatefulWidget {
  const AdminPOSScreen({super.key});

  @override
  State<AdminPOSScreen> createState() => _AdminPOSScreenState();
}

class _AdminPOSScreenState extends State<AdminPOSScreen>
    with SingleTickerProviderStateMixin {
  final _orange = const Color.fromARGB(255, 233, 73, 25);
  final _bg = const Color(0xFFFAFAFA);

  // Carrito POS
  final List<Map<String, dynamic>> _cart = [];

  // Cliente / pedido
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  String _metodoPago = 'Efectivo';
  String _retiro = 'Local';

  // Horarios (20:00 a 23:30 cada 15 min)
  late final List<String> _timeSlots;
  String? _horaSeleccionada;

  late final TabController _tab;

  // ── Datos desde tu API ──────────────────────────────────────────────────────
  List<Map<String, dynamic>> _hamburguesas = [];
  List<Map<String, dynamic>> _extras = [];
  bool _loadingHamb = true, _loadingExtras = true;
  String? _errHamb, _errExtras;

  static const String _base =
      'https://macavi-1049571319674.southamerica-west1.run.app';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);

    _timeSlots = _generateTimeSlots(
      const TimeOfDay(hour: 20, minute: 0),
      const TimeOfDay(hour: 23, minute: 30),
      stepMinutes: 15,
    );
    _horaSeleccionada = _timeSlots.first;

    _fetchHamburguesas();
    _fetchExtras();
  }

  @override
  void dispose() {
    _tab.dispose();
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  // ── Helpers horarios ───────────────────────────────────────────────────────
  List<String> _generateTimeSlots(TimeOfDay start, TimeOfDay end,
      {int stepMinutes = 15}) {
    final out = <String>[];
    int s = start.hour * 60 + start.minute;
    final e = end.hour * 60 + end.minute;
    for (int m = s; m <= e; m += stepMinutes) {
      final h = (m ~/ 60).toString().padLeft(2, '0');
      final mm = (m % 60).toString().padLeft(2, '0');
      out.add('$h:$mm');
    }
    return out;
  }

  // ── Fetch API ───────────────────────────────────────────────────────────────
  Future<void> _fetchHamburguesas() async {
    setState(() {
      _loadingHamb = true;
      _errHamb = null;
    });
    try {
      final res = await http.get(Uri.parse('$_base/hamburguesas'));
      if (res.statusCode == 200) {
        final list =
            (json.decode(res.body) as List).cast<Map<String, dynamic>>();
        _hamburguesas = list
            .map((e) => {
                  'id': e['id'],
                  'nombre': e['name'] ?? e['nombre'],
                  'precio': e['price'] ?? e['precio'],
                  'imagen': e['imagen'],
                })
            .toList();
      } else {
        _errHamb = 'HTTP ${res.statusCode}';
      }
    } catch (e) {
      _errHamb = '$e';
    } finally {
      if (mounted) setState(() => _loadingHamb = false);
    }
  }

  Future<void> _fetchExtras() async {
    setState(() {
      _loadingExtras = true;
      _errExtras = null;
    });
    try {
      final res = await http.get(Uri.parse('$_base/extras'));
      if (res.statusCode == 200) {
        final list =
            (json.decode(res.body) as List).cast<Map<String, dynamic>>();
        _extras = list
            // .where((e) => '${e['type']}'.toLowerCase() == 'acompanamiento')
            .map((e) => {
                  'id': e['id'],
                  'nombre': e['name'] ?? e['nombre'],
                  'precio': e['price'] ?? e['precio'],
                  'imagen': e['imagen'],
                })
            .toList();
      } else {
        _errExtras = 'HTTP ${res.statusCode}';
      }
    } catch (e) {
      _errExtras = '$e';
    } finally {
      if (mounted) setState(() => _loadingExtras = false);
    }
  }

  // ── Carrito ────────────────────────────────────────────────────────────────
  void _addHamburguesaFromMap(Map<String, dynamic> data) {
    _cart.add({
      'tipo': 'hamburguesa',
      'id': data['id'],
      'nombre': data['nombre'] ?? 'Hamburguesa',
      'precio': _toDouble(data['precio']) ?? 0.0,
      'cantidad': 1,
      'extras': <Map<String, dynamic>>[],
    });
    setState(() {});
  }

  void _addExtraFromMap(Map<String, dynamic> data) {
    final idx = _cart.lastIndexWhere((e) => e['tipo'] == 'hamburguesa');
    if (idx == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero agregá una hamburguesa.')),
      );
      return;
    }
    _cart[idx]['extras'].add({
      'id': data['id'],
      'nombre': data['nombre'] ?? 'Extra',
      'precio': _toDouble(data['precio']) ?? 0.0,
      'cantidad': 1,
    });
    setState(() {});
  }

  void _incItem(int i) {
    _cart[i]['cantidad'] = (_cart[i]['cantidad'] as int) + 1;
    setState(() {});
  }

  void _decItem(int i) {
    final q = (_cart[i]['cantidad'] as int);
    if (q > 1) {
      _cart[i]['cantidad'] = q - 1;
    } else {
      _cart.removeAt(i);
    }
    setState(() {});
  }

  void _removeExtra(int i, int j) {
    _cart[i]['extras'].removeAt(j);
    setState(() {});
  }

  double _calcTotal() {
    double total = 0;
    for (final item in _cart) {
      final base = (_toDouble(item['precio']) ?? 0) * (item['cantidad'] as int);
      final extras = (item['extras'] as List).fold<double>(
          0,
          (acc, ex) =>
              acc + (_toDouble(ex['precio']) ?? 0) * (ex['cantidad'] as int));
      total += base + extras;
    }
    return double.parse(total.toStringAsFixed(2));
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.'));
    return null;
  }

  // ── Guardar pedido en Firestore ────────────────────────────────────────────
  Future<void> _enviarComanda() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El carrito está vacío.')),
      );
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final pedido = {
      'items': _cart,
      'total': _calcTotal(),
      'cliente': _nombreCtrl.text.trim(),
      'telefono': _telefonoCtrl.text.trim(),
      'direccion': _direccionCtrl.text.trim(),
      'pago': _metodoPago,
      'retiro': _retiro,
      'hora': _horaSeleccionada, // ⏰ nuevo campo
      'estado': 'pendiente',
      'origen': 'pos',
      'atendidoPor': uid,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      final ref =
          await FirebaseFirestore.instance.collection('pedidos').add(pedido);

      await FirebaseFirestore.instance
          .collection('pedidos')
          .doc(ref.id)
          .collection('eventos')
          .add({'tipo': 'imprimir_comanda', 'ts': FieldValue.serverTimestamp()});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comanda enviada.')),
      );

      setState(() {
        _cart.clear();
        _nombreCtrl.clear();
        _telefonoCtrl.clear();
        _direccionCtrl.clear();
        _metodoPago = 'Efectivo';
        _retiro = 'Local';
        _horaSeleccionada = _timeSlots.first;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar comanda: $e')),
      );
    }
  }

  Future<void> _whatsapp(String phone, String msg) async {
    final url =
        Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(msg)}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
      );
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('POS — Macavi Admin',
            style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: _orange,
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Hamburguesas'),
            Tab(text: 'Extras'),
          ],
        ),
      ),
      body: Row(
        children: [
          // Panel de productos (izquierda)
          Expanded(
            flex: 6,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Seleccioná productos',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      _ProductosDesdeLista(
                        loading: _loadingHamb,
                        error: _errHamb,
                        items: _hamburguesas,
                        onAdd: _addHamburguesaFromMap,
                      ),
                      _ProductosDesdeLista(
                        loading: _loadingExtras,
                        error: _errExtras,
                        items: _extras,
                        onAdd: _addExtraFromMap,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Carrito (derecha)
          Expanded(
            flex: 7,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.only(topLeft: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(-2, 0),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Text('Carrito',
                            style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text('Total: \$${_calcTotal().toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 18, fontFamily: 'Poppins')),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _cart.isEmpty
                        ? const Center(
                            child: Text('Sin items',
                                style: TextStyle(fontFamily: 'Poppins')))
                        : ListView.builder(
                            itemCount: _cart.length,
                            itemBuilder: (ctx, i) {
                              final it = _cart[i];
                              final extras = (it['extras'] as List)
                                  .cast<Map<String, dynamic>>();
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '${it['nombre']} — \$${_toDouble(it['precio'])?.toStringAsFixed(2) ?? '0.00'}',
                                            style: const TextStyle(
                                                fontFamily: 'Poppins'),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.remove_circle_outline),
                                            onPressed: () => _decItem(i),
                                          ),
                                          Text('${it['cantidad']}'),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.add_circle_outline),
                                            onPressed: () => _incItem(i),
                                          ),
                                        ],
                                      ),
                                      if (extras.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 8.0, top: 4),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text('Extras:',
                                                  style: TextStyle(
                                                      fontFamily: 'Poppins')),
                                              ...List.generate(extras.length,
                                                  (j) {
                                                final ex = extras[j];
                                                return Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        '${ex['nombre']} — \$${_toDouble(ex['precio'])?.toStringAsFixed(2) ?? '0.00'}',
                                                        style: const TextStyle(
                                                            fontFamily:
                                                                'Poppins'),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                          Icons.close),
                                                      onPressed: () =>
                                                          _removeExtra(i, j),
                                                    ),
                                                  ],
                                                );
                                              })
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Datos del cliente',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _nombreCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _telefonoCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Teléfono',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _direccionCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Dirección',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _RadioRow(
                                label: 'Pago',
                                value: _metodoPago,
                                options: const ['Efectivo', 'Transferencia'],
                                onChanged: (v) =>
                                    setState(() => _metodoPago = v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _RadioRow(
                                label: 'Retiro',
                                value: _retiro,
                                options: const ['Local', 'Delivery'],
                                onChanged: (v) => setState(() => _retiro = v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // ⏰ Selector de hora
                            Expanded(
                              child: _TimeSlotField(
                                label: 'Hora',
                                value: _horaSeleccionada,
                                slots: _timeSlots,
                                onChanged: (v) =>
                                    setState(() => _horaSeleccionada = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _orange,
                                  shape: const StadiumBorder(),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: _enviarComanda,
                                icon: const Icon(Icons.print),
                                label: const Text('Enviar comanda',
                                    style:
                                        TextStyle(fontFamily: 'Poppins')),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    setState(() => _cart.clear()),
                                child: const Padding(
                                  padding:
                                      EdgeInsets.symmetric(vertical: 14),
                                  child: Text('Vaciar',
                                      style: TextStyle(
                                          fontFamily: 'Poppins')),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget Lista simple desde arrays ─────────────────────────────────────────
class _ProductosDesdeLista extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic>) onAdd;

  const _ProductosDesdeLista({
    required this.loading,
    required this.error,
    required this.items,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
          child: Text('Error: $error',
              style: const TextStyle(fontFamily: 'Poppins')));
    }
    if (items.isEmpty) {
      return const Center(
          child: Text('Sin datos',
              style: TextStyle(fontFamily: 'Poppins')));
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final d = items[i];
        final nombre = d['nombre']?.toString() ?? 'Item';
        final precio = d['precio'];
        return ListTile(
          title: Text(nombre,
              style: const TextStyle(fontFamily: 'Poppins')),
          subtitle: Text(precio != null ? '\$${precio.toString()}' : ''),
          trailing: ElevatedButton(
            onPressed: () => onAdd(d),
            child: const Text('Agregar'),
          ),
        );
      },
    );
  }
}

class _RadioRow extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _RadioRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: options
              .map((o) => ChoiceChip(
                    label: Text(o),
                    selected: value == o,
                    onSelected: (_) => onChanged(o),
                  ))
              .toList(),
        )
      ],
    );
  }
}

// ── Selector de hora con Dropdown ────────────────────────────────────────────
class _TimeSlotField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> slots;
  final ValueChanged<String> onChanged;

  const _TimeSlotField({
    required this.label,
    required this.value,
    required this.slots,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value ?? (slots.isNotEmpty ? slots.first : null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: selected,
          items: slots
              .map((h) =>
                  DropdownMenuItem<String>(value: h, child: Text(h)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
