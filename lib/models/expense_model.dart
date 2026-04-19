import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String concepto; // Ej: "Pago CFE", "Cloro", "Reparación"
  final double monto;
  final DateTime fecha;

  ExpenseModel({
    required this.id,
    required this.concepto,
    required this.monto,
    required this.fecha,
  });

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ExpenseModel(
      id: doc.id,
      concepto: data['concepto'] ?? '',
      monto: (data['monto'] ?? 0).toDouble(),
      fecha: (data['fecha'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'concepto': concepto,
      'monto': monto,
      'fecha': fecha,
    };
  }
}