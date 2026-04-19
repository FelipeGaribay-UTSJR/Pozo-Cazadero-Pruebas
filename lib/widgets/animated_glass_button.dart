import 'package:flutter/material.dart';

class AnimatedGlassButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? color;

  const AnimatedGlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.color,
  });

  @override
  State<AnimatedGlassButton> createState() => _AnimatedGlassButtonState();
}

class _AnimatedGlassButtonState extends State<AnimatedGlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Si no le pasamos un color, usará el color Menta que definimos en main.dart
    final buttonColor = widget.color ?? Theme.of(context).colorScheme.primary;

    return GestureDetector(
      // Cuando el dedo toca la pantalla, se encoge
      onTapDown: (_) => setState(() => _isPressed = true),
      // Si el dedo se desliza fuera del botón, cancela la animación
      onTapCancel: () => setState(() => _isPressed = false),
      // Cuando el dedo se levanta, vuelve a su tamaño y ejecuta la acción
      onTapUp: (_) {
        setState(() => _isPressed = false);
        // Le damos 100 milisegundos para que el usuario alcance a ver cómo rebota antes de cambiar de pantalla
        Future.delayed(const Duration(milliseconds: 100), () {
          widget.onPressed();
        });
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.90 : 1.0, // Se encoge al 90% de su tamaño
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
          decoration: BoxDecoration(
            color: buttonColor.withOpacity(0.85), // Ligeramente transparente
            borderRadius: BorderRadius.circular(30), // Súper redondeado
            boxShadow: [
              BoxShadow(
                color: buttonColor.withOpacity(0.4), // Sombra del mismo color que el botón
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
            // El toque Glassmorphism: un borde blanco semi-transparente
            border: Border.all(
              color: Colors.white.withOpacity(0.6),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}