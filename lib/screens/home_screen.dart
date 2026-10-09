
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/caminhada.dart';
import '../services/banco_dados.dart';
import 'detalhes_caminhada_screen.dart';
import 'nova_caminhada_screen.dart';
import 'splash_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback aoAlterarTema;
  final bool temaEscuro;

  const HomeScreen({
    super.key,
    required this.aoAlterarTema,
    required this.temaEscuro,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Caminhada>> _caminhadas;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    _caminhadas = BancoDados.listar();
  }

  Future<void> _abrirNovaCaminhada() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NovaCaminhadaScreen(),
      ),
    );

    if (mounted) {
      setState(_carregar);
    }
  }

  void _abrirSplash() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SplashScreen(
          aoAlterarTema: widget.aoAlterarTema,
          temaEscuro: widget.temaEscuro,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Minhas caminhadas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              DrawerHeader(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_walk,
                        size: 48,
                        color: cor.primary,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Caminhadas',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Home'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.animation_outlined),
                title: const Text('Splash'),
                onTap: _abrirSplash,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Tema escuro'),
                value: widget.temaEscuro,
                onChanged: (_) {
                  Navigator.pop(context);
                  widget.aoAlterarTema();
                },
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sair'),
                onTap: () async {
                  final sair = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sair do aplicativo?'),
                      content: const Text(
                        'Suas caminhadas continuarão salvas.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.pop(context, true),
                          child: const Text('Sair'),
                        ),
                      ],
                    ),
                  );

                  if (sair == true && mounted) {
                    await SystemNavigator.pop();
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      body: FutureBuilder<List<Caminhada>>(
        future: _caminhadas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Erro ao carregar caminhadas.'),
            );
          }

          final caminhadas = snapshot.data ?? [];

          if (caminhadas.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_walk_outlined,
                      size: 90,
                      color: cor.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sua próxima caminhada começa aqui!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Toque no botão + para registrar '
                      'seu primeiro percurso.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: caminhadas.length,
            itemBuilder: (context, index) {
              final caminhada = caminhadas[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: cor.primaryContainer,
                    child: Icon(
                      Icons.route,
                      color: cor.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    caminhada.titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${caminhada.distanciaKm.toStringAsFixed(2)} km'
                      '  •  ${caminhada.tempoMinutos} min\n'
                      '${caminhada.calorias.toStringAsFixed(0)} kcal',
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetalhesCaminhadaScreen(
                          caminhada: caminhada,
                        ),
                      ),
                    );

                    if (mounted) {
                      setState(_carregar);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNovaCaminhada,
        icon: const Icon(Icons.add),
        label: const Text('Nova caminhada'),
      ),
    );
  }
}