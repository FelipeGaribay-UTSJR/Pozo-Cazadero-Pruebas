import 'dart:typed_data';
import 'package:printing/printing.dart';
import '../services/api_service.dart';

class PdfService {
  final ApiService _apiService = ApiService();

  Future<void> imprimirRecibo(Map<String, dynamic> recibo) async {
    final String reciboId = recibo['recibo_id'] ?? '';
    final String periodoLabel = recibo['periodo_label'] ?? 'Recibo';

    if (reciboId.isEmpty) {
      print("Error: El recibo no tiene un ID válido.");
      return;
    }

    // 1. Le pedimos el archivo PDF oficial a la API
    final List<int>? bytes = await _apiService.descargarTicketPdfBytes(reciboId);

    // 2. Revisamos si la API nos mandó el PDF o nos mandó a volar (como en los pendientes)
    if (bytes != null && bytes.isNotEmpty) {
      
      final Uint8List pdfData = Uint8List.fromList(bytes);

      // 3. Usamos sharePdf. En la Web, esto fuerza la DESCARGA del archivo.
      // Así evitamos que Vercel o el navegador bloqueen la ventana de impresión.
      await Printing.sharePdf(
        bytes: pdfData,
        filename: 'Ticket_${periodoLabel.replaceAll(" ", "_")}.pdf',
      );
      
    } else {
      // ⚠️ AQUÍ ESTÁ EL TEMA DE LOS PENDIENTES
      print("❌ El servidor NO devolvió el PDF del recibo $reciboId.");
      print("Probablemente la API no genera tickets para recibos con estatus 'Pendiente'.");
      // Opcional: Aquí podrías mostrar un SnackBar en pantalla que diga: 
      // "Este recibo aún no está pagado o no tiene ticket disponible."
    }
  }
}