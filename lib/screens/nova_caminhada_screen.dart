
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/caminhada.dart';
import '../services/banco_dados.dart';
import '../services/rota_services.dart';

class NovaCaminhadaScreen extends StatefulWidget {
  const NovaCaminhadaScreen({super.key});

  @override
  State<NovaCaminhadaScreen> createState() =>
      _NovaCaminhadaScreenState();
}

class _NovaCaminhadaScreenState
    extends State<NovaCaminhadaScreen> {
  final MapController _mapController = MapController();

  LatLng? _inicio;
  LatLng? _destino;
  List<LatLng> _pontos = [];

  double _distanciaKm = 0;
  double _calorias = 0;
  int _tempoMinutos = 0;

  bool _carregando = true;
  bool _calculandoRota = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _obterLocalizacao();
  }

  Future<void> _obterLocalizacao() async {
    try {
      final servicoAtivo =
          await Geolocator.isLocationServiceEnabled();

      if (!servicoAtivo) {
        throw Exception('Ative o serviço de localização do celular.');
      }

      LocationPermission permissao =
          await Geolocator.checkPermission();

      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }

      if (permissao == LocationPermission.denied ||
          permissao == LocationPermission.deniedForever) {
        throw Exception(
          'Permita o acesso à localização nas configurações.',
        );
      }

      final posicao = await Geolocator.getCurrentPosition();

      if (!mounted) return;

      setState(() {
        _inicio = LatLng(
          posicao.latitude,
          posicao.longitude,
        );
        _carregando = false;
      });

      _mapController.move(_inicio!, 15);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
        _carregando = false;
      });
    }
  }

  Future<void> _selecionarDestino(LatLng destino) async {
    if (_inicio == null) return;

    setState(() {
      _destino = destino;
      _pontos = [];
      _calculandoRota = true;
      _erro = null;
    });

    try {
      final resultado = await RotaService.calcularRota(
        _inicio!,
        destino,
      );

      if (!mounted) return;

      setState(() {
        _pontos = resultado['pontos'] as List<LatLng>;
        _distanciaKm = resultado['distanciaKm'] as double;
        _calorias = resultado['calorias'] as double;
        _tempoMinutos = resultado['tempoMinutos'] as int;
        _calculandoRota = false;
      });

      if (_pontos.isNotEmpty) {
        final limites = LatLngBounds.fromPoints(_pontos);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: limites,
            padding: const EdgeInsets.all(48),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _calculandoRota = false;
        _erro = 'Não foi possível calcular a rota. '
            'Verifique sua conexão e tente outro destino.';
      });
    }
  }

  Future<void> _salvar() async {
    if (_destino == null || _pontos.isEmpty) return;

    final controlador = TextEditingController();

    final titulo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salvar caminhada'),
        content: TextField(
          controller: controlador,
          autofocus: true,
          maxLength: 50,
          decoration: const InputDecoration(
            labelText: 'Título da caminhada',
            hintText: 'Ex.: Caminhada no parque',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (valor) {
            if (valor.trim().isNotEmpty) {
              Navigator.pop(context, valor.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (controlador.text.trim().isNotEmpty) {
                Navigator.pop(
                  context,
                  controlador.text.trim(),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    controlador.dispose();

    if (titulo == null || !mounted) return;

    final caminhada = Caminhada(
      titulo: titulo,
      latitudeInicial: _inicio!.latitude,
      longitudeInicial: _inicio!.longitude,
      latitudeFinal: _destino!.latitude,
      longitudeFinal: _destino!.longitude,
      distanciaKm: _distanciaKm,
      calorias: _calorias,
      tempoMinutos: _tempoMinutos,
      trajeto: _pontos,
      data: DateTime.now().toIso8601String(),
    );

    await BancoDados.inserir(caminhada);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Caminhada salva com sucesso!')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova caminhada')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _inicio == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_off, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _erro ?? 'Não foi possível obter sua localização.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _carregando = true;
                              _erro = null;
                            });
                            _obterLocalizacao();
                          },
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Text(
                            'Toque no mapa para selecionar o destino.',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_erro != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _erro!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _inicio!,
                          initialZoom: 15,
                          onTap: (tapPosition, ponto) {
                            _selecionarDestino(ponto);
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.caminhadas',
                          ),
                          if (_pontos.isNotEmpty)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: _pontos,
                                  strokeWidth: 5,
                                  color: Colors.green,
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _inicio!,
                                width: 44,
                                height: 44,
                                child: const Icon(
                                  Icons.my_location,
                                  color: Colors.blue,
                                  size: 34,
                                ),
                              ),
                              if (_destino != null)
                                Marker(
                                  point: _destino!,
                                  width: 44,
                                  height: 44,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 40,
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
                    if (_calculandoRota)
                      const LinearProgressIndicator(),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _informacao(
                                'Distância',
                                '${_distanciaKm.toStringAsFixed(2)} km',
                                Icons.route,
                              ),
                              _informacao(
                                'Tempo',
                                '$_tempoMinutos min',
                                Icons.schedule,
                              ),
                              _informacao(
                                'Calorias',
                                '${_calorias.toStringAsFixed(0)} kcal',
                                Icons.local_fire_department,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _destino != null &&
                                      _pontos.isNotEmpty &&
                                      !_calculandoRota
                                  ? _salvar
                                  : null,
                              icon: const Icon(Icons.save_outlined),
                              label: const Text('Salvar caminhada'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _informacao(String titulo, String valor, IconData icone) {
    return Expanded(
      child: Column(
        children: [
          Icon(icone, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Text(titulo, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}