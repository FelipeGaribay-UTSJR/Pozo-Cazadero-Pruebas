import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Quité la importación de ReceiptModel por ahora para usar el Map directo
import '../services/database_service.dart';
import '../services/pdf_service.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ReceiptDetailScreen extends StatefulWidget {
  // Ahora recibimos el mapa exacto del JSON y algunos datos extra si los tienes
  final Map<String, dynamic> recibo;
  final String numeroContrato; 
  final String nombreUsuario; // Pasarlo desde el login/perfil
  final String direccion; // Pasarlo desde el login/perfil

  const ReceiptDetailScreen({
    super.key, 
    required this.recibo,
    this.numeroContrato = 'N/A',
    this.nombreUsuario = 'USUARIO DEMO',
    this.direccion = 'DIRECCIÓN DEMO',
  });

  @override
  _ReceiptDetailScreenState createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends State<ReceiptDetailScreen> {
  final PdfService _pdfService = PdfService();
  final DatabaseService _dbService = DatabaseService();
  bool _isLoadingPayment = false;

  Future<void> _iniciarPagoMercadoPago() async {
    setState(() => _isLoadingPayment = true);
    
    // Obtenemos los totales y el recibo desde el JSON actual
    double totalAPagar = (widget.recibo['total'] ?? 0).toDouble();
    String periodoLabel = widget.recibo['periodo_label'] ?? 'PERIODO';

    // Asumimos que el ID del recibo en el backend puede llamarse 'id', 'recibo_id' o 'folio'
    String reciboId = widget.recibo['id']?.toString() ?? widget.recibo['recibo_id']?.toString() ?? widget.recibo['folio']?.toString() ?? '';
    
    if (reciboId.isEmpty) {
      setState(() => _isLoadingPayment = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: ID del recibo local no encontrado."), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // Llama al microservicio en Vercel
    final String? paymentUrl = await ApiService().generarLinkMercadoPago(
      reciboId: reciboId,
      monto: totalAPagar,
      titulo: "Recibo ${widget.numeroContrato} - $periodoLabel",
    );
    
    if (!mounted) return;
    setState(() => _isLoadingPayment = false);

    if (paymentUrl != null && paymentUrl.isNotEmpty) {
      final Uri url = Uri.parse(paymentUrl);
      if (await canLaunchUrl(url)) {
        // Lanzamos el link de Mercado Pago (Checkout Pro)
        await launchUrl(url, mode: LaunchMode.externalApplication);
        
        // Al regresar a la app, preguntamos si completó el pago
        if (mounted) {
           _mostrarDialogoConfirmacion(reciboId);
        }

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo abrir la página de Mercado Pago."), backgroundColor: Colors.red),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hubo un problema al generar el cobro."), backgroundColor: Colors.red),
      );
    }
  }

  void _mostrarDialogoConfirmacion(String reciboId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Verificación de Pago"),
        content: const Text("¿Completaste el pago exitosamente en Mercado Pago?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cierra si no pagó
            child: const Text("No, cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Cierra modal
              setState(() => _isLoadingPayment = true);
              
              // Registra en Hydra que el usuario reporta el recibo como pagado
              bool exito = await ApiService().registrarPagoHydra(reciboId, 'pago_mp_externo_movil');
              
              if (mounted) {
                setState(() => _isLoadingPayment = false);
                if (exito) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Pago registrado exitosamente. El estado se actualizará en breve."), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context, true); // Regresa al historial indicando que hay cambios
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Error al notificar al sistema principal."), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("Sí, ya pagué"),
          )
        ],
      ),
    );
  }

  // --- Herramientas para dibujar la tabla ---
  Widget _buildGridRow(List<Widget> cells, {bool isLast = false, double minHeight = 25}) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Colors.black, width: 1.0)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: cells,
        ),
      ),
    );
  }

  Widget _buildCell(String text, {
    int flex = 1,
    bool rightBorder = true,
    bool bold = false,
    bool italic = false,
    double fontSize = 10,
    Alignment alignment = Alignment.centerLeft,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          border: rightBorder ? const Border(right: BorderSide(color: Colors.black, width: 1.0)) : null,
        ),
        alignment: alignment,
        child: Text(
          text,
          textAlign: alignment == Alignment.center ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            fontSize: fontSize,
            color: Colors.black,
            fontFamily: 'Arial',
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyCell(double val, {int flex = 1, bool rightBorder = true}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          border: rightBorder ? const Border(right: BorderSide(color: Colors.black, width: 1.0)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('\$', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black)),
            Text(val == 0 ? '-' : val.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    
    // --- LEYENDO EL JSON REAL ---
    bool pagado = widget.recibo['estado'] == 'pagado';
    String periodoLabel = widget.recibo['periodo_label'] ?? 'PERIODO';
    double totalAPagar = (widget.recibo['total'] ?? 0).toDouble();
    List<dynamic> lineas = widget.recibo['lineas'] ?? [];
    
    // Fechas
    DateTime fechaEmision = DateTime.tryParse(widget.recibo['fecha_emision'] ?? '') ?? DateTime.now();
    String fechaVencimientoStr = widget.recibo['fecha_vencimiento'] ?? '';
    
    // Colores dinámicos
    Color estadoColor = pagado ? Colors.green : theme.error;
    String estadoTexto = pagado ? "PAGADO" : "PENDIENTE DE PAGO";

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Detalle del Recibo", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.primary,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.primary.withOpacity(0.15),
              theme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    // --- ESTADO FLOTANTE ---
                    Container(
                      margin: const EdgeInsets.only(bottom: 20, top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: estadoColor.withOpacity(0.5), width: 2),
                        boxShadow: [
                          BoxShadow(color: estadoColor.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))
                        ]
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            pagado ? Icons.check_circle_rounded : Icons.warning_rounded,
                            color: estadoColor,
                          ),
                          const SizedBox(width: 8),
                          Text(estadoTexto, style: TextStyle(color: estadoColor, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                        ],
                      ),
                    ),

                    // --- LA TABLA EXACTA DEL RECIBO FISICO ---
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 1.5),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
                        ]
                      ),
                      child: Column(
                        children: [
                          _buildGridRow([_buildCell("RECIBO DE PAGO", flex: 1, rightBorder: false, alignment: Alignment.center, fontSize: 9)]),
                          _buildGridRow([_buildCell(periodoLabel.toUpperCase(), flex: 1, rightBorder: false, bold: true, fontSize: 20, alignment: Alignment.center)], minHeight: 35),
                          _buildGridRow([
                            _buildCell("MES DE FACTURACION\n", flex: 4, bold: true, alignment: Alignment.topLeft),
                            _buildCell("CONTRATO", flex: 3, bold: true, alignment: Alignment.center),
                            _buildCell(widget.numeroContrato, flex: 3, bold: true, rightBorder: false, alignment: Alignment.center, fontSize: 14),
                          ]),
                          _buildGridRow([
                            _buildCell("NOMBRE", flex: 4, bold: true),
                            _buildCell(widget.nombreUsuario, flex: 6, bold: true, italic: true, rightBorder: false, alignment: Alignment.center, fontSize: 12),
                          ]),
                          _buildGridRow([
                            _buildCell("DIRECCION", flex: 4, bold: true),
                            _buildCell(widget.direccion, flex: 6, rightBorder: false, alignment: Alignment.center),
                          ]),
                          
                          // Encabezados de Conceptos
                          _buildGridRow([
                            _buildCell("CONCEPTO", flex: 4, bold: true, alignment: Alignment.center),
                            _buildCell("IMPORTE", flex: 3, bold: true, alignment: Alignment.center),
                            _buildCell("CANT.", flex: 3, rightBorder: false, bold: true, alignment: Alignment.center),
                          ]),
                          
                          // --- CICLO DINÁMICO PARA LAS LÍNEAS DEL JSON ---
                          ...lineas.map((linea) {
                            return _buildGridRow([
                              _buildCell(linea['descripcion'].toString().toUpperCase(), flex: 4, bold: true),
                              _buildCurrencyCell((linea['subtotal'] ?? 0).toDouble(), flex: 3),
                              _buildCell(linea['cantidad'].toString(), flex: 3, rightBorder: false, alignment: Alignment.center)
                            ]);
                          }),

                          // --- TOTAL ---
                          _buildGridRow([
                            _buildCell("TOTAL A PAGAR", flex: 4, bold: true),
                            Expanded(
                              flex: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('\$', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                                    Text(totalAPagar.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                                  ],
                                ),
                              ),
                            )
                          ]),
                          
                          _buildGridRow([
                            _buildCell("FECHA EMISIÓN", flex: 4, bold: true),
                            _buildCell(DateFormat('dd/MMM/yyyy', 'es').format(fechaEmision).toUpperCase(), flex: 6, bold: true, rightBorder: false, alignment: Alignment.center, fontSize: 11),
                          ]),
                          
                          if (fechaVencimientoStr.isNotEmpty)
                            _buildGridRow([
                              _buildCell("VENCIMIENTO", flex: 4, bold: true),
                              _buildCell(fechaVencimientoStr, flex: 6, bold: true, rightBorder: false, alignment: Alignment.center, fontSize: 11),
                            ]),

                          Container(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                Text(
                                  "PARA CUALQUIER ACLARACION TRAER RECIBO ANTERIOR",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue[900]),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    const Column(
                                      children: [
                                        Icon(Icons.water_drop, size: 40, color: Colors.blue),
                                        Text("POZO EL CAZADERO, A.C.", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    Container(
                                      width: 150,
                                      height: 80,
                                      decoration: BoxDecoration(border: Border.all(color: Colors.grey), color: Colors.grey[200]),
                                      alignment: Alignment.center,
                                      child: const Text("Cédula SAT\n(Imagen aquí)", textAlign: TextAlign.center, style: TextStyle(fontSize: 10)),
                                    )
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --- BOTONES DE ACCIÓN ---
                    if (!pagado) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF009EE3),
                            foregroundColor: Colors.white,
                            elevation: 5,
                            shadowColor: const Color(0xFF009EE3).withOpacity(0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                          ),
                          icon: _isLoadingPayment 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.payment_rounded, size: 28),
                          label: Text(
                            _isLoadingPayment ? "PROCESANDO..." : "PAGAR CON MERCADO PAGO", 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)
                          ),
                          onPressed: _isLoadingPayment ? null : _iniciarPagoMercadoPago,
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.primary,
                          side: BorderSide(color: theme.primary.withOpacity(0.5), width: 1.5),
                          backgroundColor: Colors.white.withOpacity(0.6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
                        icon: const Icon(Icons.download_rounded),
                        label: const Text("DESCARGAR RECIBO EN PDF", style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                           _pdfService.imprimirRecibo(widget.recibo); // Descomentar cuando actualices tu PdfService
                        },
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}