
import 'package:flutter/material.dart';

import '../models/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback aoAlterarTema;
  final bool temaEscuro;

  const SplashScreen({
    super.key,
    required this.aoAlterarTema,
    required this.temaEscuro,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animacao;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _animacao = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, animation, secondaryAnimation) {
            return FadeTransition(
              opacity: animation,
              child: HomeScreen(
                aoAlterarTema: widget.aoAlterarTema,
                temaEscuro: widget.temaEscuro,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 700),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: ScaleTransition(
          scale: _animacao,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cor.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_walk_rounded,
                  size: 72,
                  color: cor.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Caminhadas',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Cada passo conta.'),
            ],
          ),
        ),
      ),
    );
  }
}