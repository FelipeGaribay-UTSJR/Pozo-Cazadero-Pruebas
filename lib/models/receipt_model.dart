import 'package:cloud_firestore/cloud_firestore.dart';

class ReceiptModel {
  final String id;
  final String userId;
  final String nombreUsuario;
  final String numeroMedidor;
  final DateTime fechaEmision;
  final double consumoM3;
  final double montoTotal;
  final String periodo;
  final bool pagado;
  final String comprobanteUrl;
  final String direccion;
  final double lecturaAnterior;
  final double lecturaActual;
  final double adeudoAnterior;
  final double recargos;
  final double extras;
  final double faltaAsamblea;
  final double drenaje;

  ReceiptModel({
    required this.id,
    required this.userId,
    required this.nombreUsuario,
    required this.numeroMedidor,
    required this.fechaEmision,
    required this.consumoM3,
    required this.montoTotal,
    required this.periodo,
    required this.pagado,
    required this.comprobanteUrl,
    required this.direccion,
    required this.lecturaAnterior,
    required this.lecturaActual,
    required this.adeudoAnterior,
    required this.recargos,
    required this.extras,
    required this.faltaAsamblea,
    required this.drenaje,
  });

  // --- LA MAGIA: Lee el JSON de la API Hydra y lo adapta a tu Pantalla ---
  factory ReceiptModel.fromJson(
    Map<String, dynamic> json, {
    String nombre = '',
    String direccion = '',
    String medidor = '',
  }) {
    List<dynamic> lineas = json['lineas'] ?? [];

    double drenajeCalc = 0;
    double asambleaCalc = 0;
    double recargosCalc = 0;
    double adeudoCalc = 0;

    // Filtramos las líneas del recibo para sacar los costos exactos
    for (var linea in lineas) {
      String desc = (linea['descripcion'] ?? '').toString().toLowerCase();
      double monto = (linea['monto'] ?? 0).toDouble();

      if (desc.contains('drenaje')) {
        drenajeCalc += monto;
      } else if (desc.contains('multa') || desc.contains('asamblea'))
        asambleaCalc += monto;
      else if (desc.contains('recargo') || desc.contains('mora'))
        recargosCalc += monto;
      else if (desc.contains('adeudo') || desc.contains('anterior'))
        adeudoCalc += monto;
    }

    return ReceiptModel(
      id: json['recibo_id']?.toString() ?? '',
      userId: '', // Ya no usamos uid de Firebase
      nombreUsuario: nombre,
      numeroMedidor: medidor,
      fechaEmision: json['periodo'] != null
          ? DateTime.parse(json['periodo'])
          : DateTime.now(),
      consumoM3:
          0, // Si quieres extraerlo del texto, puedes hacerlo en el for de arriba
      montoTotal: (json['total'] ?? 0).toDouble(),
      periodo: json['periodo_label']?.toString() ?? '',
      pagado: json['estado'] == 'pagado',
      comprobanteUrl: '',
      direccion: direccion,
      lecturaAnterior: 0,
      lecturaActual: 0,
      adeudoAnterior: adeudoCalc,
      recargos: recargosCalc,
      extras: 0,
      faltaAsamblea: asambleaCalc,
      drenaje: drenajeCalc,
    );
  }

  // --- COMPATIBILIDAD FIREBASE (Dejado aquí para que no marque error database_service) ---
  factory ReceiptModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ReceiptModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      nombreUsuario: data['nombreUsuario'] ?? '',
      numeroMedidor: data['numeroMedidor'] ?? '',
      fechaEmision: (data['fechaEmision'] as Timestamp).toDate(),
      consumoM3: (data['consumoM3'] ?? 0).toDouble(),
      montoTotal: (data['montoTotal'] ?? 0).toDouble(),
      periodo: data['periodo'] ?? '',
      pagado: data['pagado'] ?? false,
      comprobanteUrl: data['comprobanteUrl'] ?? '',
      direccion: data['direccion'] ?? '',
      lecturaAnterior: (data['lecturaAnterior'] ?? 0).toDouble(),
      lecturaActual: (data['lecturaActual'] ?? 0).toDouble(),
      adeudoAnterior: (data['adeudoAnterior'] ?? 0).toDouble(),
      recargos: (data['recargos'] ?? 0).toDouble(),
      extras: (data['extras'] ?? 0).toDouble(),
      faltaAsamblea: (data['faltaAsamblea'] ?? 0).toDouble(),
      drenaje: (data['drenaje'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {};
  } // Evita errores viejos
}
