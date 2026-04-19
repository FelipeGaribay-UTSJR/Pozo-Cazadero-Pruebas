import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/pdf_service.dart';
import '../widgets/water_drop_mascot.dart';
// Importamos la pantalla de detalle que acabamos de crear
import 'receipt_detail_screen.dart'; 

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final ApiService _apiService = ApiService();
  final PdfService _pdfService = PdfService();
  
  // Cambiamos ReceiptModel por dynamic para leer el JSON directo de la API
  late Future<List<dynamic>> _misRecibos;

  @override
  void initState() {
    super.initState();
    _cargarRecibos();
  }

  void _cargarRecibos() {
    setState(() {
      _misRecibos = _apiService.obtenerMisRecibos(); 
    });
  }

  void _cerrarSesion() async {
    await _apiService.logout(); 
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Recibos"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
          )
        ],
      ),
      body: Column(
        children: [
          const WaterDropMascot(),
          Expanded(
            child: FutureBuilder<List<dynamic>>( // Ajustado a List<dynamic>
              future: _misRecibos,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error al cargar: ${snapshot.error}", textAlign: TextAlign.center),
                  );
                }

                var recibos = snapshot.data ?? [];
                
                if (recibos.isEmpty) {
                  return const Center(child: Text("No tienes recibos en tu historial"));
                }

                return ListView.builder(
                  itemCount: recibos.length,
                  itemBuilder: (context, index) {
                    // Ahora recibo es exactamente el mapa JSON que vimos en Postman
                    final recibo = recibos[index];
                    
                    bool estaPagado = recibo['estado'] == 'pagado';
                    Color colorEstado = estaPagado ? Colors.green : Colors.orange;
                    String textoEstado = estaPagado ? "PAGADO" : "PENDIENTE";
                    String periodo = recibo['periodo_label'] ?? 'Mes';
                    double total = (recibo['total'] ?? 0).toDouble();

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Icon(
                          estaPagado ? Icons.check_circle : Icons.warning_rounded, 
                          color: colorEstado, 
                          size: 36
                        ),
                        title: Text(periodo.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Total: \$${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w500)),
                            Text("Estado: $textoEstado", style: TextStyle(color: colorEstado, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                        
                        // --- ¡AQUÍ ESTÁ LA MAGIA DE LA NAVEGACIÓN! ---
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReceiptDetailScreen(
                                recibo: recibo, // Le pasamos el JSON del recibo específico
                                // Aquí puedes pasar datos estáticos por ahora
                                numeroContrato: "CTR-0003", 
                                nombreUsuario: "Juan Pérez", 
                                direccion: "Calle Conocida #123",
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}