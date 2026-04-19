import 'package:flutter/material.dart';
import 'create_report_screen.dart'; 
import 'login_screen.dart'; // Importamos la pantalla de login
import '../widgets/water_drop_mascot.dart';
import '../widgets/animated_glass_button.dart';

class PublicHomeScreen extends StatelessWidget {
  const PublicHomeScreen({super.key});

  // Ahora este botón nos lleva al Login Oficial
  void _irALogin(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        // --- AQUÍ ESTÁ EL DEGRADADO DE FONDO (Menta a Lavanda) ---
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.primary.withOpacity(0.3), // Menta muy suave arriba
              theme.secondary.withOpacity(0.2), // Azul lavanda suave abajo
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    
                    // LLAMAMOS A LA MASCOTA COMO PROTAGONISTA
                    const WaterDropMascot(),
                    const SizedBox(height: 20),
                    
                    Text(
                      "Servicio de Agua", 
                      style: TextStyle(
                        fontSize: 34, 
                        fontWeight: FontWeight.w800, 
                        color: theme.primary, // Texto en color Menta
                        letterSpacing: -0.5
                      )
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Inicia sesión para consultar tus recibos de agua o reporta fugas fácilmente.", 
                      style: TextStyle(fontSize: 16, color: Colors.black54, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // --- BOTÓN PRINCIPAL PARA IR A INICIAR SESIÓN ---
                    AnimatedGlassButton(
                      text: "INICIAR SESIÓN",
                      onPressed: () => _irALogin(context),
                    ),
                    
                    const SizedBox(height: 50),
                    
                    // BOTONES SECUNDARIOS (ESTILO GLASSMORPHISM)
                    Row(
                      children: [
                        Expanded(
                          child: _GlassSquareButton(
                            icon: Icons.warning_amber_rounded,
                            color: Colors.orangeAccent.shade400,
                            titulo: "Reportar\nFuga",
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateReportScreen())),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- NUEVA VERSIÓN DEL BOTÓN SECUNDARIO ESTILO GLASSMORPHISM ---
class _GlassSquareButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String titulo;
  final VoidCallback onTap;

  const _GlassSquareButton({required this.icon, required this.color, required this.titulo, required this.onTap});

  @override
  State<_GlassSquareButton> createState() => _GlassSquareButtonState();
}

class _GlassSquareButtonState extends State<_GlassSquareButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        Future.delayed(const Duration(milliseconds: 100), widget.onTap);
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6), // Fondo semitransparente (Glass)
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 2), // Borde blanco brillante
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ]
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, size: 28, color: widget.color),
              ),
              const SizedBox(height: 12),
              Text(
                widget.titulo, 
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)
              )
            ],
          ),
        ),
      ),
    );
  }
}