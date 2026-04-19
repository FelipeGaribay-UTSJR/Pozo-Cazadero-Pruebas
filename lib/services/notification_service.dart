import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_auth/firebase_auth.dart';
// LIBRERÍA NUEVA LIGERA (Asegúrate de haber hecho: flutter pub add dart_jsonwebtoken)
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart'; 

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // TU VAPID KEY (Para que no se congele el login en Web)
  final String _vapidKey = "BA10PXzkxsreitaLDgNhlmWh789wXUjb71fC2GW1vML46Y1JwRczrblAgKEG1IOgFm_MA8rPq3oCGYuo1If32qU";

  /// Inicializa
  Future<void> initNotifications() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permisos OK.');
      // Escuchar Login
      _auth.authStateChanges().listen((User? user) {
        if (user != null) uploadTokenForUser(user.uid);
      });
    }
  }

  /// SUBIR TOKEN
  Future<void> uploadTokenForUser(String userId) async {
    try {
      // Usamos vapidKey para que funcione en PWA
      String? token = await _messaging.getToken(vapidKey: kIsWeb ? _vapidKey : null);

      if (token != null) {
        await _db.collection('users').doc(userId).update({
          'fcmToken': token,
          'platform': kIsWeb ? 'PWA' : 'Mobile',
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        print("✅ Token guardado: $userId");
      }
    } catch (e) {
      print("Error guardando token: $e");
    }
  }

  /// ENVIAR NOTIFICACIÓN (Lógica Manual V1 - Compatible con Web)
  Future<void> notifyAdminsOfNewReport(String tipoReporte) async {
    try {
      // 1. Buscamos admins
      var admins = await _db.collection('users').where('rol', isEqualTo: 'admin').get();
      if (admins.docs.isEmpty) return;

      // 2. OBTENER ACCESS TOKEN MANUALMENTE (Esto reemplaza a googleapis_auth)
      String? accessToken = await _getAccessTokenManual();
      if (accessToken == null) {
        print("❌ No se pudo generar el Access Token");
        return;
      }

      // Leemos el Project ID del JSON también
      final jsonString = await rootBundle.loadString('secrets/service_account.json');
      final serviceAccount = jsonDecode(jsonString);
      final projectId = serviceAccount['project_id'];

      // 3. Enviar a cada admin
      for (var doc in admins.docs) {
        String? token = doc.data()['fcmToken'];
        if (token != null) {
          await _sendPushV1(token, tipoReporte, projectId, accessToken);
        }
      }
      print("🚀 Notificaciones enviadas.");

    } catch (e) {
      print("❌ Error enviando: $e");
    }
  }

  

  /// MAGIA PURA: Genera el token de Google manualmente sin librerías pesadas
  Future<String?> _getAccessTokenManual() async {
    try {
      // Leemos el JSON
      final jsonString = await rootBundle.loadString('secrets/service_account.json');
      final serviceAccount = jsonDecode(jsonString);

      // Creamos el JWT
      final jwt = JWT(
        {
          "iss": serviceAccount['client_email'],
          "scope": "https://www.googleapis.com/auth/firebase.messaging",
          "aud": "https://oauth2.googleapis.com/token",
          "iat": DateTime.now().millisecondsSinceEpoch ~/ 1000,
          "exp": (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600, // 1 hora
        },
      );

      // Firmamos con la llave privada (RS256)
      final key = RSAPrivateKey(serviceAccount['private_key']); 
      final signedJwt = jwt.sign(key, algorithm: JWTAlgorithm.RS256);

      // Intercambiamos el JWT por un Access Token real de Google
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': signedJwt,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['access_token'];
      } else {
        print("Error obteniendo token Google: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error generando credenciales manuales: $e");
      return null;
    }
  }

  /// Función de Envío HTTP V1
  Future<void> _sendPushV1(String token, String tipoReporte, String projectId, String accessToken) async {
    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': token,
            'notification': {
              'title': '¡Nuevo Reporte!',
              'body': 'Tipo: $tipoReporte',
            },
            // Configuración Web
            'webpush': {
              'notification': {
                'icon': '/icons/Icon-192.png',
                'click_action': '/admin_dashboard'
              }
            },
            // Configuración Android
            'android': {
              'notification': {
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              }
            }
          }
        }),
      );
    } catch (e) {
      print("Error HTTP envío: $e");
    }
  }
}