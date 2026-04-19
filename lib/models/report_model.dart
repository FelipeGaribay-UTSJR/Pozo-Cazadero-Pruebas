import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String tipo; // "Fuga", "Falta de agua", "Calidad", "Otro"
  final String descripcion;
  final String fotoUrl; // La URL de la imagen en internet
  final String estado; // "Pendiente", "En Reparación", "Resuelto"
  final DateTime fechaReporte;
  
  // 1. NUEVO CAMPO: Mapa para latitud y longitud
  final Map<String, dynamic>? ubicacion; 

  ReportModel({
    required this.id,
    required this.tipo,
    required this.descripcion,
    required this.fotoUrl,
    required this.estado,
    required this.fechaReporte,
    this.ubicacion, // <--- Lo agregamos al constructor (es opcional)
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      tipo: data['tipo'] ?? '',
      descripcion: data['descripcion'] ?? '',
      fotoUrl: data['fotoUrl'] ?? '',
      estado: data['estado'] ?? 'Pendiente',
      fechaReporte: (data['fechaReporte'] as Timestamp).toDate(),
      
      // 2. RECUPERAR DE FIREBASE
      // Si existe el campo 'ubicacion', lo tomamos, si no, queda nulo.
      ubicacion: data['ubicacion'] is Map ? data['ubicacion'] : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'descripcion': descripcion,
      'fotoUrl': fotoUrl,
      'estado': estado,
      'fechaReporte': fechaReporte,
      
      // 3. GUARDAR EN FIREBASE
      'ubicacion': ubicacion, 
    };
  }
}