import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  late final GenerativeModel _model;
  ChatSession? _chat;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'AIzaSyBCHuDbpA9qv4l9BGAd4Lv063ufgFy8XLc') {
      print('ERROR: No se encontró GEMINI_API_KEY en el archivo .env');
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey ?? 'ERROR_NO_API_KEY',
      systemInstruction: Content.system(
        'Eres el asistente virtual de la App del Pozo de Agua. '
        'Tu objetivo es ayudar a los vecinos con respuestas breves y amables. '
        'DATOS CLAVE: '
        '- Horario de bombeo: Lun, Mie, Vie de 6:00 AM a 10:00 AM. '
        '- Costo: 50 pesos al mes. '
        '- Fugas: Pedir que cierren llave de paso y reporten en la sección "Reportes". '
        '- Si te insultan o preguntan cosas ajenas al agua, responde educadamente que solo hablas del pozo.'
      ),
    );
    // Iniciamos el chat
    _chat = _model.startChat();
  }

  Future<String?> sendMessage(String message) async {
    try {
      final response = await _chat?.sendMessage(Content.text(message));
      return response?.text;
    } catch (e) {
      print('Error en GeminiService: $e'); // Log visual en consola
      return "Error de conexión con el asistente. Verifica que hayas configurado tu API Key localmente.";
    }
  }
}