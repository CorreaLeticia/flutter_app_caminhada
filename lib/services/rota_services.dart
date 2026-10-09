
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RotaService {
  static Future<Map<String, dynamic>> calcularRota(
    LatLng inicio,
    LatLng destino,
  ) async {
    final url = Uri.parse(
      'https://routing.openstreetmap.de/routed-foot/route/v1/driving/'
      '${inicio.longitude},${inicio.latitude};'
      '${destino.longitude},${destino.latitude}'
      '?overview=full&geometries=geojson',
    );

    final resposta = await http.get(url).timeout(
      const Duration(seconds: 20),
    );

    if (resposta.statusCode != 200) {
      throw Exception('Não foi possível calcular a rota.');
    }

    final dados = jsonDecode(resposta.body);

    if (dados['code'] != 'Ok' ||
        (dados['routes'] as List).isEmpty) {
      throw Exception('Nenhuma rota encontrada.');
    }

    final rota = dados['routes'][0];
    final coordenadas = rota['geometry']['coordinates'] as List;

    final pontos = coordenadas.map((p) {
      return LatLng(
        (p[1] as num).toDouble(),
        (p[0] as num).toDouble(),
      );
    }).toList();

    final distanciaKm =
        (rota['distance'] as num).toDouble() / 1000;

    final tempoMinutos = (distanciaKm / 5 * 60).ceil();
    final calorias = distanciaKm * 60;

    return {
      'pontos': pontos,
      'distanciaKm': distanciaKm,
      'tempoMinutos': tempoMinutos,
      'calorias': calorias,
    };
  }
}