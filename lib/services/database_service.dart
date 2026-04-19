import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/receipt_model.dart';
import '../models/user_model.dart';
import '../models/report_model.dart'; // Importa el nuevo modelo
import '../models/expense_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Usuarios (Admin) ---
  Future<void> registrarMedidor(String nombre, String medidor, String direccion) async {
    await _db.collection('users').add({
      'nombre': nombre,
      'numeroMedidor': medidor,
      'direccion': direccion,
      'rol': 'usuario',
      'email': '', // Opcional
      'fechaRegistro': DateTime.now(),
    });
  }

  Stream<List<UserModel>> obtenerTodosLosMedidores() {
    return _db.collection('users')
        .where('rol', isEqualTo: 'usuario')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<UserModel?> obtenerUsuario(String uid) async {
    DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
    }
    return null;
  }

  // --- Recibos ---
  Future<void> agregarRecibo(ReceiptModel recibo) async {
    await _db.collection('receipts').add(recibo.toMap());
  }

  // --- Función para ELIMINAR Recibo ---
  Future<void> eliminarRecibo(String id) async {
    await _db.collection('receipts').doc(id).delete();
  }

  Stream<List<ReceiptModel>> obtenerTodosLosRecibos() {
    return _db.collection('receipts').orderBy('fechaEmision', descending: true)
        .snapshots().map((snapshot) => snapshot.docs
        .map((doc) => ReceiptModel.fromFirestore(doc)).toList());
  }

  // Búsqueda pública (Requiere índice compuesto en Firestore)
  Stream<List<ReceiptModel>> buscarRecibosPorMedidor(String medidor) {
    return _db.collection('receipts')
        .where('numeroMedidor', isEqualTo: medidor)
        .orderBy('fechaEmision', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ReceiptModel.fromFirestore(doc)).toList());
  }
  
  Stream<List<ReceiptModel>> obtenerMisRecibos(String uid) {
    return _db.collection('receipts')
        .where('userId', isEqualTo: uid)
        .orderBy('fechaEmision', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ReceiptModel.fromFirestore(doc)).toList());
  }

  Future<void> cambiarEstadoPago(String reciboId, bool nuevoEstado) async {
    await _db.collection('receipts').doc(reciboId).update({
      'pagado': nuevoEstado
    });
  }

  // Guardar reporte (La foto viene como String Base64 dentro del modelo)
  Future<void> crearReporte(ReportModel reporte) async {
    await _db.collection('reports').add(reporte.toMap());
  }

  // Obtener Reportes
  Stream<List<ReportModel>> obtenerReportes() {
    return _db.collection('reports')
        .orderBy('fechaReporte', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ReportModel.fromFirestore(doc)).toList());
  }

  // Actualizar Estado
  Future<void> actualizarEstadoReporte(String id, String nuevoEstado) async {
    await _db.collection('reports').doc(id).update({'estado': nuevoEstado});
  }

  // --- Función para ELIMINAR Reporte ---
  Future<void> eliminarReporte(String id) async {
    await _db.collection('reports').doc(id).delete();
  }

  // --- MODO LECTURISTA ---

  // Obtener usuarios ordenados por número de medidor (La Ruta)
  Stream<List<UserModel>> obtenerRutaLectura() {
    return _db.collection('users')
        .where('rol', isEqualTo: 'usuario')
        .orderBy('numeroMedidor') // Ordenamos por medidor para seguir la calle
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList());
  }

  // Guardar la lectura: Crea recibo Y actualiza al usuario
  Future<void> procesarLectura(UserModel usuario, double lecturaActual, double consumo, double monto, String periodo) async {
    // 1. Crear el recibo
    final recibo = ReceiptModel(
      id: '',
      userId: usuario.uid,
      nombreUsuario: usuario.nombre,
      numeroMedidor: usuario.numeroMedidor,
      fechaEmision: DateTime.now(),
      consumoM3: consumo,
      montoTotal: monto,
      periodo: periodo,
      pagado: false,
      comprobanteUrl: '',
      direccion: 'CONOCIDO',
      lecturaAnterior: 0.0,
      lecturaActual: 0.0,
      adeudoAnterior: 0.0,
      recargos: 0.0,
      extras: 0.0,
      faltaAsamblea: 0.0,
      drenaje: 0.0,
    );
    
    await _db.collection('receipts').add(recibo.toMap());

    // 2. Actualizar la última lectura del usuario para el próximo mes
    await _db.collection('users').doc(usuario.uid).update({
      'ultimaLectura': lecturaActual
    });
  }

// --- GASTOS Y TRANSPARENCIA ---

  // 1. Agregar un gasto (Admin)
  Future<void> agregarGasto(String concepto, double monto) async {
    await _db.collection('expenses').add({
      'concepto': concepto,
      'monto': monto,
      'fecha': DateTime.now(),
    });
  }

  // 2. Obtener lista de gastos ordenados por fecha
  Stream<List<ExpenseModel>> obtenerGastos() {
    return _db.collection('expenses')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ExpenseModel.fromFirestore(doc)).toList());
  }

  // 3. Eliminar gasto
  Future<void> eliminarGasto(String id) async {
    await _db.collection('expenses').doc(id).delete();
  }

  // --- PAGOS Y COMPROBANTES ---

  // Vecino sube el comprobante (Actualizamos el recibo existente)
  Future<void> subirComprobante(String reciboId, String base64Foto) async {
    await _db.collection('receipts').doc(reciboId).update({
      'comprobanteUrl': base64Foto,
      // Opcional: Podrías poner un campo 'estado' = 'En Revisión', 
      // pero por ahora usaremos: si tiene foto y pagado=false, es revisión.
    });
  }

  // --- ACTUALIZACIONES Y BORRADOS (NUEVO) ---

  // 1. Editar Medidor (Usuario)
  Future<void> editarUsuario(String uid, String nombre, String medidor, String direccion) async {
    await _db.collection('users').doc(uid).update({
      'nombre': nombre,
      'numeroMedidor': medidor,
      'direccion': direccion,
    });
  }

  // 2. Eliminar Medidor (Usuario)
  Future<void> eliminarUsuario(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  // 3. Editar Recibo (Corregir errores)
  Future<void> editarRecibo(String id, double consumo, double monto, String periodo) async {
    await _db.collection('receipts').doc(id).update({
      'consumoM3': consumo,
      'montoTotal': monto,
      'periodo': periodo,
    });
  }

  // 4. Editar Gasto
  Future<void> editarGasto(String id, String concepto, double monto) async {
    await _db.collection('expenses').doc(id).update({
      'concepto': concepto,
      'monto': monto,
    });
  }
}