import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://hydra-real.vercel.app/api/ciudadanos';

  // --------------------------------------------------------
  // 1. INICIAR SESIÓN
  // --------------------------------------------------------
  Future<bool> login(String folioOEmail, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    
    final jsonAEnviar = jsonEncode({
      'folio': folioOEmail.trim(),
      'password': password.trim(),
    });

    print('>>> JSON que se va a enviar: $jsonAEnviar');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonAEnviar,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        
        await prefs.setString('access_token', data['access_token']);
        await prefs.setString('refresh_token', data['refresh_token']);
        
        if (data['contratos'] != null && data['contratos'].isNotEmpty) {
          final contrato = data['contratos'][0]; 
          await prefs.setString('contrato_id', contrato['contrato_id']);
        }
        return true; // ¡Acceso concedido!
      } else {
        return false; // Rechazado
      }
    } catch (e) {
      return false; // Error de internet
    }
  }

  // --------------------------------------------------------
  // 2. RENOVAR SESIÓN (REFRESH TOKEN) INVISIBLE
  // --------------------------------------------------------
  Future<bool> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    
    if (refreshToken == null) return false;

    final url = Uri.parse('$baseUrl/auth/refresh');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Guardamos las llaves nuevas
        await prefs.setString('access_token', data['access_token']);
        await prefs.setString('refresh_token', data['refresh_token']);
        return true;
      }
      return false; // El refresh token también expiró o es inválido
    } catch (e) {
      return false;
    }
  }

  // --------------------------------------------------------
  // 3. OBTENER RECIBOS (Con auto-reintento y JSON dinámico)
  // --------------------------------------------------------
  Future<List<dynamic>> obtenerMisRecibos() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token == null) throw Exception('No hay token');

    // Cambiamos al endpoint que te funcionó en Postman
    final url = Uri.parse('$baseUrl/me/recibos');
    
    try {
      var response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Si el token expiró (401), lo renovamos en automático
      if (response.statusCode == 401) {
        print("Token expirado. Intentando renovar...");
        bool refreshed = await refreshToken();
        
        if (refreshed) {
          token = prefs.getString('access_token');
          response = await http.get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
        } else {
          await logout();
          throw Exception('Sesión totalmente expirada. Vuelve a iniciar sesión.');
        }
      }
    
      // Si todo salió bien, devolvemos la lista cruda
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        
        // El JSON de tu Postman traía la lista directo en la llave "recibos"
        List<dynamic> recibosJson = decoded['recibos'] ?? [];
        
        return recibosJson;
      }
      
      return [];
    } catch (e) {
      print("Error al obtener recibos: $e");
      return [];
    }
  }

  // --------------------------------------------------------
  // 4. DESCARGAR TICKET EN PDF (Endpoint Oficial)
  // --------------------------------------------------------
  Future<List<int>?> descargarTicketPdfBytes(String reciboId) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    if (token == null) return null;

    final url = Uri.parse('$baseUrl/me/recibos/$reciboId/ticket');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else if (response.statusCode == 401) {
        return null; 
      }
      return null;
    } catch (e) {
      print('Error al descargar PDF: $e');
      return null;
    }
  }

  // --------------------------------------------------------
  // 5. GENERAR LINK DE MERCADO PAGO (Microservicio Vercel local)
  // --------------------------------------------------------
  Future<String?> generarLinkMercadoPago({
    required String reciboId,
    required double monto,
    required String titulo,
  }) async {
    // IMPORTANTE: Cuando despliegues en Vercel, esta será la ruta a la función.
    // Mientras pruebas localmente en Android/iOS, necesitas usar la URL completa de Vercel.
    // Ej: const String pwaDomain = 'https://tu-proyecto-agua.vercel.app';
    const String pwaDomain = 'https://hydra-real.vercel.app'; // Cámbialo si tu PWA tiene otro dominio
    final url = Uri.parse('$pwaDomain/api/mercadopago');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "recibo_id": reciboId, 
          "monto": monto,
          "titulo": titulo
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['init_point']; // Link generado exitosamente
      } else {
        print('Error en Vercel Function: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error de conexión a Vercel: $e');
      return null;
    }
  }

  // --------------------------------------------------------
  // 6. REGISTRAR PAGO COMPLETADO EN HYDRA
  // --------------------------------------------------------
  Future<bool> registrarPagoHydra(String reciboId, String referenciaExterna) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    if (token == null) return false;

    // Llama a la API oficial de Hydra para marcar el recibo como pagado
    final url = Uri.parse('$baseUrl/me/recibos/$reciboId/pagar');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          "metodo_pago": "externo", 
          "referencia_externa": referenciaExterna 
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error al notificar a Hydra del pago: $e');
      return false;
    }
  }

  // --------------------------------------------------------
  // 6. CERRAR SESIÓN
  // --------------------------------------------------------
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('contrato_id');
  }
}