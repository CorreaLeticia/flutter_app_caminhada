
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:latlong2/latlong.dart';

import '../models/caminhada.dart';
import '../services/banco_dados.dart';

class DetalhesCaminhadaScreen extends StatefulWidget {
  final Caminhada caminhada;

  const DetalhesCaminhadaScreen({
    super.key,
    required this.caminhada,
  });

  @override
  State<DetalhesCaminhadaScreen> createState() =>
      _DetalhesCaminhadaScreenState();
}

class _DetalhesCaminhadaScreenState
    extends State<DetalhesCaminhadaScreen> {
  late Caminhada _caminhada;
  bool _tirandoFoto = false;

  @override
  void initState() {
    super.initState();
    _caminhada = widget.caminhada;
  }

  Future<void> _tirarFoto() async {
    try {
      setState(() => _tirandoFoto = true);

      final imagem = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (imagem == null) {
        if (mounted) setState(() => _tirandoFoto = false);
        return;
      }

      final diretorio = await getApplicationDocumentsDirectory();
      final nomeArquivo =
          'caminhada_${_caminhada.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final arquivo = await File(imagem.path).copy(
        '${diretorio.path}/$nomeArquivo',
      );

      final atualizada = Caminhada(
        id: _caminhada.id,
        titulo: _caminhada.titulo,
        latitudeInicial: _caminhada.latitudeInicial,
        longitudeInicial: _caminhada.longitudeInicial,
        latitudeFinal: _caminhada.latitudeFinal,
        longitudeFinal: _caminhada.longitudeFinal,
        distanciaKm: _caminhada.distanciaKm,
        calorias: _caminhada.calorias,
        tempoMinutos: _caminhada.tempoMinutos,
        foto: arquivo.path,
        trajeto: _caminhada.trajeto,
        data: _caminhada.data,
      );

      await BancoDados.atualizar(atualizada);

      if (!mounted) return;

      setState(() {
        _caminhada = atualizada;
        _tirandoFoto = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _tirandoFoto = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível registrar a foto.'),
        ),
      );
    }
  }

  Future<void> _excluirCaminhada() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir caminhada?'),
        content: const Text(
          'Essa ação não poderá ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    await BancoDados.excluir(_caminhada.id!);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme;
    final pontos = _caminhada.trajeto;

    final centro = pontos.isNotEmpty
        ? pontos[pontos.length ~/ 2]
        : LatLng(
            _caminhada.latitudeInicial,
            _caminhada.longitudeInicial,
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(_caminhada.titulo),
        actions: [
          IconButton(
            onPressed: _excluirCaminhada,
            tooltip: 'Excluir caminhada',
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 260,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: centro,
                  initialZoom: 14,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.caminhadas',
                  ),
                  if (pontos.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: pontos,
                          strokeWidth: 5,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          _caminhada.latitudeInicial,
                          _caminhada.longitudeInicial,
                        ),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 32,
                        ),
                      ),
                      Marker(
                        point: LatLng(
                          _caminhada.latitudeFinal,
                          _caminhada.longitudeFinal,
                        ),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Resumo da caminhada',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _linha(
                    Icons.route,
                    'Distância',
                    '${_caminhada.distanciaKm.toStringAsFixed(2)} km',
                  ),
                  const Divider(height: 24),
                  _linha(
                    Icons.schedule,
                    'Tempo estimado',
                    '${_caminhada.tempoMinutos} minutos',
                  ),
                  const Divider(height: 24),
                  _linha(
                    Icons.local_fire_department,
                    'Gasto calórico estimado',
                    '${_caminhada.calorias.toStringAsFixed(0)} kcal',
                  ),
                  const Divider(height: 24),
                  _linha(
                    Icons.calendar_today,
                    'Data',
                    _caminhada.data.substring(0, 10),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Foto da caminhada',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          if (_caminhada.foto != null &&
              File(_caminhada.foto!).existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(_caminhada.foto!),
                height: 260,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: cor.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  Icons.photo_camera_outlined,
                  size: 60,
                  color: cor.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _tirandoFoto ? null : _tirarFoto,
            icon: const Icon(Icons.camera_alt),
            label: Text(
              _tirandoFoto
                  ? 'Abrindo câmera...'
                  : _caminhada.foto == null
                      ? 'Tirar foto'
                      : 'Tirar outra foto',
            ),
          ),
        ],
      ),
    );
  }

  Widget _linha(IconData icone, String titulo, String valor) {
    return Row(
      children: [
        Icon(icone, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(titulo)),
        Text(
          valor,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}