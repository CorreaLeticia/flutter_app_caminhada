
import 'dart:convert';

import 'package:latlong2/latlong.dart';

class Caminhada {
  final int? id;
  final String titulo;
  final double latitudeInicial;
  final double longitudeInicial;
  final double latitudeFinal;
  final double longitudeFinal;
  final double distanciaKm;
  final double calorias;
  final int tempoMinutos;
  final String? foto;
  final List<LatLng> trajeto;
  final String data;

  Caminhada({
    this.id,
    required this.titulo,
    required this.latitudeInicial,
    required this.longitudeInicial,
    required this.latitudeFinal,
    required this.longitudeFinal,
    required this.distanciaKm,
    required this.calorias,
    required this.tempoMinutos,
    this.foto,
    required this.trajeto,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'latitudeInicial': latitudeInicial,
      'longitudeInicial': longitudeInicial,
      'latitudeFinal': latitudeFinal,
      'longitudeFinal': longitudeFinal,
      'distanciaKm': distanciaKm,
      'calorias': calorias,
      'tempoMinutos': tempoMinutos,
      'foto': foto,
      'trajeto': jsonEncode(
        trajeto.map((p) => [p.latitude, p.longitude]).toList(),
      ),
      'data': data,
    };
  }

  factory Caminhada.fromMap(Map<String, dynamic> map) {
    final pontos = jsonDecode(map['trajeto'] as String) as List;

    return Caminhada(
      id: map['id'] as int?,
      titulo: map['titulo'] as String,
      latitudeInicial: (map['latitudeInicial'] as num).toDouble(),
      longitudeInicial: (map['longitudeInicial'] as num).toDouble(),
      latitudeFinal: (map['latitudeFinal'] as num).toDouble(),
      longitudeFinal: (map['longitudeFinal'] as num).toDouble(),
      distanciaKm: (map['distanciaKm'] as num).toDouble(),
      calorias: (map['calorias'] as num).toDouble(),
      tempoMinutos: map['tempoMinutos'] as int,
      foto: map['foto'] as String?,
      trajeto: pontos.map((p) {
        return LatLng(
          (p[0] as num).toDouble(),
          (p[1] as num).toDouble(),
        );
      }).toList(),
      data: map['data'] as String,
    );
  }
}