import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:macavi/screens/admin_pos_screen.dart';

class PerfilScreen extends StatefulWidget {
  final int puntosTotales;
  final List<Map<String, dynamic>> carritoProductos;
  final String userId;

  const PerfilScreen({
    super.key,
    required this.puntosTotales,
    required this.carritoProductos,
    required this.userId,
  });

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  // Cache de prefs y logo
  late SharedPreferences _prefs;
  final Image _logo =
      const Image(image: AssetImage('assets/logomacavi.png'), width: 60, height: 60);

  // Campos del perfil
  String nombrePerfil = 'Usuario de Macavi';
  String userEmail = 'usuario@email.com';
  String userPhone = '3400000000';
  String userBirth = '01/01/2000';
  String userStreet = 'Calle sin nombre 123';
  String userCity = 'Arroyo Seco';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await _cargarDatos();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(_logo.image, context);
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() {
      nombrePerfil = _prefs.getString('user_name') ?? nombrePerfil;
      userEmail = _prefs.getString('user_email') ?? userEmail;
      userPhone = _prefs.getString('user_phone') ?? userPhone;
      userBirth = _prefs.getString('user_birth') ?? userBirth;
      userStreet = _prefs.getString('user_street') ?? userStreet;
      userCity = _prefs.getString('user_city') ?? userCity;
    });
  }

  // ---- Editores ----

  Future<void> _editarTextoSheet({
    required String titulo,
    required String clavePrefs,
    required String valorActual,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String value)? validator,
  }) async {
    final controller = TextEditingController(text: valorActual);

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Color(0xFFE94719), width: 2),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE94719),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                keyboardType: keyboardType,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Escribí aquí',
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE94719), width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                onSubmitted: (_) => Navigator.pop(ctx, controller.text.trim()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE94719),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancelar'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE94719),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (result == null) return;
    final v = result.trim();
    if (validator != null) {
      final err = validator(v);
      if (err != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
        return;
      }
    }
    if (v.isEmpty || v == valorActual) return;

    await _prefs.setString(clavePrefs, v);
    if (!mounted) return;
    setState(() {
      switch (clavePrefs) {
        case 'user_email':
          userEmail = v;
          break;
        case 'user_phone':
          userPhone = v;
          break;
        case 'user_street':
          userStreet = v;
          break;
        case 'user_city':
          userCity = v;
          break;
        case 'user_name':
          nombrePerfil = v;
          break;
      }
    });
  }

  Future<void> _editarFechaNacimiento() async {
    DateTime? initial;
    try {
      final p = userBirth.split('/');
      if (p.length == 3) {
        initial = DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
      }
    } catch (_) {}
    initial ??= DateTime(2000, 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Seleccioná tu fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Guardar',
    );

    if (picked != null) {
      final dd = picked.day.toString().padLeft(2, '0');
      final mm = picked.month.toString().padLeft(2, '0');
      final yyyy = picked.year.toString();
      final formateada = '$dd/$mm/$yyyy';

      await _prefs.setString('user_birth', formateada);
      if (!mounted) return;
      setState(() => userBirth = formateada);
    }
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      bottomNavigationBar: _buildBottomNavigationBar(context),
      backgroundColor: const Color.fromARGB(255, 236, 229, 221),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Icon(Icons.account_circle, size: 100, color: Color(0xFFE94719)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _editarTextoSheet(
                    titulo: 'Nombre',
                    clavePrefs: 'user_name',
                    valorActual: nombrePerfil,
                  ),
                  child: Text(
                    nombrePerfil.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontFamily: 'NewGroteskSquare',
                      color: Color(0xFFE94719),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 🔥 Botón para ir al Admin POS
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE94719),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const AdminPOSScreen()),
                    );
                  },
                  icon: const Icon(Icons.storefront),
                  label: const Text(
                    'Ir al Panel Admin',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                _buildSectionTitle('DATOS PERSONALES'),
                _buildEditableItem(
                  'Correo electrónico',
                  userEmail,
                  onTap: () => _editarTextoSheet(
                    titulo: 'Correo electrónico',
                    clavePrefs: 'user_email',
                    valorActual: userEmail,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v.isEmpty) return 'El correo no puede estar vacío';
                      if (!v.contains('@') || !v.contains('.')) return 'Correo inválido';
                      return null;
                    },
                  ),
                ),
                _buildEditableItem(
                  'Teléfono',
                  userPhone,
                  onTap: () => _editarTextoSheet(
                    titulo: 'Teléfono',
                    clavePrefs: 'user_phone',
                    valorActual: userPhone,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v.isEmpty) return 'El teléfono no puede estar vacío';
                      if (v.replaceAll(RegExp(r'[^0-9+]'), '').length < 6) {
                        return 'Teléfono inválido';
                      }
                      return null;
                    },
                  ),
                ),
                _buildEditableItem(
                  'Fecha de nacimiento',
                  userBirth,
                  onTap: _editarFechaNacimiento,
                ),

                const SizedBox(height: 20),
                _buildSectionTitle('TU UBICACIÓN'),
                _buildEditableItem(
                  'Calle',
                  userStreet,
                  onTap: () => _editarTextoSheet(
                    titulo: 'Calle',
                    clavePrefs: 'user_street',
                    valorActual: userStreet,
                  ),
                ),
                _buildEditableItem(
                  'Localidad',
                  userCity,
                  onTap: () => _editarTextoSheet(
                    titulo: 'Localidad',
                    clavePrefs: 'user_city',
                    valorActual: userCity,
                  ),
                ),

                const SizedBox(height: 30),
                _buildLogoutButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableItem(String label, String value, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      title: Text(
        label.toUpperCase(),
        style: const TextStyle(fontSize: 13, fontFamily: 'Poppins', color: Colors.grey),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 15, fontFamily: 'Poppins', color: Colors.black),
      ),
      trailing: const Text(
        'EDITAR',
        style: TextStyle(
          color: Color(0xFFE94719),
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check, size: 16, color: Color(0xFFE94719)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Poppins',
              color: Color(0xFFE94719),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Column(
      children: [
        const Divider(thickness: 1),
        TextButton.icon(
          onPressed: () => _cerrarSesion(context),
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          label: const Text(
            'Cerrar sesión',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.redAccent,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color.fromARGB(255, 237, 232, 222),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      title: Align(alignment: Alignment.center, child: _logo),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 1,
      backgroundColor: const Color.fromARGB(255, 233, 73, 25),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.fastfood, size: 28),
          label: 'Menú',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
      onTap: (index) {
        if (index == 0) Navigator.of(context).pop();
      },
    );
  }

  void _cerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión', style: TextStyle(fontFamily: 'Poppins')),
          content: const Text(
            '¿Estás seguro de que querés cerrar sesión?',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFFE94719), fontFamily: 'Poppins')),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Cerrar Sesión',
                  style: TextStyle(color: Color(0xFFE94719), fontFamily: 'Poppins')),
              onPressed: () async {
                await _prefs.clear();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacementNamed('/');
                }
              },
            ),
          ],
        );
      },
    );
  }
}