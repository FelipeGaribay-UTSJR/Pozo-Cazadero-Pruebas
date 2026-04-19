import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../models/report_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'package:url_launcher/url_launcher.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  _CreateReportScreenState createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final DatabaseService _db = DatabaseService();

  String _tipoSeleccionado = 'Fuga de Agua';
  final List<String> _tipos = [
    'Fuga de Agua',
    'Falta de Agua',
    'Calidad del Agua',
    'Otro',
  ];

  // Variables de Imagen
  Uint8List? _webImage;
  String? _base64Image;

  // Variables de Ubicación (GPS)
  Position? _ubicacionActual;
  bool _cargandoUbicacion = false;
  String _textoUbicacion = "Toca para agregar ubicación GPS";

  // Variables de Estado
  bool _isProcessing = false;
  String _statusMessage = "";

  // --- FUNCIÓN CORREGIDA PARA OBTENER UBICACIÓN (CON TIMEOUT) ---
  Future<void> _obtenerUbicacion() async {
    setState(() {
      _cargandoUbicacion = true;
      _textoUbicacion = "Buscando...";
    });

    try {
      // 1. Verificaciones de siempre
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Enciende el GPS.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Permiso denegado.';
      }
      if (permission == LocationPermission.deniedForever)
        throw 'Permisos bloqueados.';

      Position? position;

      // PASO A: Intentar leer la memoria (Caché)
      // Esto es lo que hace que Instagram se sienta instantáneo.
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (e) {
        // Si falla, no importa, seguimos al paso B
      }

      // PASO B: Si no había memoria, buscar usando Wi-Fi (Low Accuracy)
      // Usamos 'low' porque funciona dentro de casas y oficinas.
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _ubicacionActual = position;
          _textoUbicacion = "📍 Ubicación lista";
          _cargandoUbicacion = false;
        });
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) {
        setState(() {
          // Si falla incluso con Low Accuracy, es probable que no tenga señal
          _textoUbicacion = "No se pudo detectar. Intenta afuera.";
          _cargandoUbicacion = false;
        });
      }
    }
  }

  // --- FUNCIÓN PARA SELECCIONAR FOTO ---
  Future<void> _seleccionarFoto() async {
    final ImagePicker picker = ImagePicker();

    try {
      setState(() {
        _isProcessing = true;
        _statusMessage = "Abriendo cámara/galería...";
      });

      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 25,
      );

      if (image != null) {
        var f = await image.readAsBytes();

        // Límite de seguridad (aprox 700kb)
        if (f.lengthInBytes > 700000) {
          setState(() {
            _isProcessing = false;
            _statusMessage = "Imagen muy pesada, intenta otra.";
          });
          return;
        }

        String base64String = base64Encode(f);

        setState(() {
          _webImage = f;
          _base64Image = base64String;
          _isProcessing = false;
          _statusMessage = "Imagen lista para enviar";
        });
      } else {
        setState(() {
          _isProcessing = false;
          _statusMessage = "";
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = "Error: $e";
      });
    }
  }

  // --- FUNCIÓN PARA ENVIAR REPORTE ---
  // --- FUNCIÓN PARA ENVIAR REPORTE (VERSIÓN MEJORADA PARA WEB) ---
  void _enviarReporte() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
        _statusMessage = "Abriendo WhatsApp...";
      });

      try {
        // 1. Preparamos la ubicación
        Map<String, double>? mapaUbicacion;
        String linkMapas = "Sin ubicación GPS ❌";

        if (_ubicacionActual != null) {
          mapaUbicacion = {
            'lat': _ubicacionActual!.latitude,
            'lng': _ubicacionActual!.longitude,
          };
          // Link oficial y corregido de Google Maps
          linkMapas =
              "https://www.google.com/maps/search/?api=1&query=${_ubicacionActual!.latitude},${_ubicacionActual!.longitude}";
        }

        // 2. Armamos el reporte para Firebase
        final reporte = ReportModel(
          id: '',
          tipo: _tipoSeleccionado,
          descripcion: _descController.text,
          fotoUrl: _base64Image ?? "",
          estado: 'Pendiente',
          fechaReporte: DateTime.now(),
          ubicacion: mapaUbicacion,
        );

        // 3. PREPARAMOS WHATSAPP (Asegúrate de poner el número de la jefa aquí)
        String numeroWhatsApp = "524271511220";

        String mensaje =
            "🚨 *NUEVO REPORTE* 🚨\n\n"
            "💧 *Tipo:* $_tipoSeleccionado\n"
            "📝 *Descripción:* ${_descController.text}\n"
            "📍 *Ubicación:* $linkMapas\n";

        if (_webImage != null) {
          mensaje +=
              "\n📸 *(Tengo una foto del problema, te la envío por aquí en un momento)*";
        }

        String urlEscrita =
            "https://wa.me/$numeroWhatsApp?text=${Uri.encodeComponent(mensaje)}";
        Uri urlWhatsApp = Uri.parse(urlEscrita);

        // 👇 EL TRUCO ESTÁ AQUÍ 👇
        // ABRIMOS WHATSAPP PRIMERO (Sin esperas, para que Chrome no nos bloquee)
        launchUrl(urlWhatsApp, mode: LaunchMode.externalApplication);

        // LUEGO GUARDAMOS EN LA BASE DE DATOS (Se hace en el fondo)
        await _db.crearReporte(reporte).timeout(const Duration(seconds: 15));

        // ÉXITO
        if (mounted) {
          setState(() => _isProcessing = false);
          Navigator.pop(context); // Cierra la pantalla
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text("¡Reporte guardado y enviado a WhatsApp!"),
            ),
          );
        }
      } catch (e) {
        print("Error al reportar: $e");
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _statusMessage = "Error al enviar: $e";
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reportar Problema")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_statusMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        _statusMessage.contains("Error") ||
                            _statusMessage.contains("No se pudo")
                        ? Colors.red[100]
                        : Colors.yellow[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 10),

              DropdownButtonFormField(
                initialValue: _tipoSeleccionado,
                items: _tipos
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _tipoSeleccionado = val.toString()),
                decoration: const InputDecoration(
                  labelText: "Tipo de Problema",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Descripción",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v!.isEmpty ? 'La descripción es obligatoria' : null,
              ),

              const SizedBox(height: 20),

              // --- BOTÓN DE GEOLOCALIZACIÓN ---
              InkWell(
                onTap: _cargandoUbicacion ? null : _obtenerUbicacion,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _ubicacionActual != null
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                    border: Border.all(
                      color: _ubicacionActual != null
                          ? Colors.green
                          : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: _ubicacionActual != null
                            ? Colors.green
                            : Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _textoUbicacion,
                          style: TextStyle(
                            color: _ubicacionActual != null
                                ? Colors.green.shade900
                                : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_cargandoUbicacion)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- SELECCIONAR FOTO ---
              GestureDetector(
                onTap: _isProcessing ? null : _seleccionarFoto,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(
                      color: Colors.grey.shade400,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _webImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(_webImage!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Colors.grey,
                            ),
                            Text(
                              "Tocar para agregar foto (Opcional)",
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                ),
              ),

              if (_webImage != null)
                TextButton.icon(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  label: const Text(
                    "Quitar foto",
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () {
                    setState(() {
                      _webImage = null;
                      _base64Image = null;
                      _statusMessage = "";
                    });
                  },
                ),

              const SizedBox(height: 30),

              _isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _enviarReporte,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text(
                          "ENVIAR REPORTE",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
