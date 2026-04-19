import 'package:flutter/material.dart';
import 'dart:math' as math;

class WaterDropMascot extends StatefulWidget {
  const WaterDropMascot({super.key});

  @override
  State<WaterDropMascot> createState() => _WaterDropMascotState();
}

class _WaterDropMascotState extends State<WaterDropMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late String _currentTip;

  final List<String> _waterTips = [
    "¡Hola! ¿Sabías que solo el 1% del agua del planeta es dulce y accesible?",
    "Cierra la llave al cepillarte los dientes y ahorra hasta 15 litros por minuto.",
    "Una llave goteando puede desperdiciar más de 30 litros de agua al día.",
    "Toma duchas de máximo 5 minutos y salvarás hasta 100 litros cada vez.",
    "Usa la lavadora solo con cargas completas para maximizar el uso del agua.",
    "Lavar tu auto con cubeta en lugar de manguera ahorra muchísima agua.",
    "Riega tus plantas muy temprano o de noche para evitar la evaporación.",
    "Tu cerebro es 75% agua. ¡Mantener el agua limpia es vital para pensar claro!",
    "No uses el inodoro como papelera; cada descarga gasta de 6 a 12 litros.",
    "Descongelar alimentos en el refrigerador en lugar de bajo el agua ahorra litros.",
    "Si lavas platos a mano, usa dos tinas: una para enjabonar y otra para enjuagar.",
    "Reutiliza el agua de cocción de vegetales para regar plantas (¡sin sal!).",
    "Los árboles ayudan a mantener el ciclo del agua limpio y constante.",
    "Una fuga invisible en el inodoro puede desperdiciar 200 litros en un día.",
    "Un litro de aceite vertido al drenaje contamina miles de litros de agua.",
    "Báñate mientras escuchas una canción de 5 minutos ¡Ese es el tiempo ideal!",
    "Pon una botella con arena en el tanque del inodoro antiguo para ahorrar descargas.",
    "Los océanos almacenan el 97% del agua del planeta, ¡pero es salada!",
    "Recoge el agua de la regadera mientras se calienta y úsala para limpiar.",
    "Tener plantas nativas en tu jardín reduce la necesidad de riego constante.",
    "Revisa que tu medidor no se mueva cuando tienes todas las llaves cerradas.",
    "Cierra el agua mientras te enjabonas el cabello y el cuerpo en la ducha.",
    "Más de 2000 millones de personas no tienen acceso continuo a agua potable.",
    "El agua es la única sustancia presente naturalmente en estado sólido, líquido y gaseoso.",
    "Producir un kilo de carne de res requiere unos 15000 litros de agua.",
    "Producir una camiseta de algodón necesita hasta 2700 litros de agua.",
    "Al barrer la calle, usa escoba, no la manguera a presión.",
    "Aísla las tuberías de agua caliente para que se caliente más rápido.",
    "Usa jabones y detergentes biodegradables para no dañar los ríos.",
    "El agua limpia es un derecho, ¡ayudemos a conservarla para todos!",
    "Coloca aireadores en los grifos para reducir el caudal sin perder presión.",
    "Una persona necesita al menos 20 a 50 litros diarios para higiene básica.",
    "No eches restos de comida en el fregadero, tíralos en la basura.",
    "En lugar de lavar el piso con manguera, usa una jerga y cubeta.",
    "El agua regula la temperatura del planeta y también de tu cuerpo.",
    "Cerca del 70% de la extracción mundial de agua se destina a agricultura.",
    "Lava las frutas en un recipiente en vez de hacerlo bajo el chorro de agua.",
    "Un vaso de agua pura al despertar activa los órganos de tu cuerpo.",
    "Aprovecha el agua de lluvia para bañar a tus mascotas.",
    "Cambia tus electrodomésticos viejos por unos de bajo consumo hídrico.",
    "Si el inodoro sigue sonando tras la descarga, arréglalo cuanto antes.",
    "No tires medicinas por el drenaje, contaminan los cuerpos de agua.",
    "Producir una sola hoja de papel puede costar hasta 10 litros de agua.",
    "Asegúrate de que tus mascotas siempre tengan agua fresca y purificada.",
    "Usa el agua de cocer huevos para tus plantas; es nutritiva.",
    "Un niño con agua limpia y saneamiento asiste a la escuela regularmente.",
    "Los humedales son como esponjas que filtran agua y evitan inundaciones.",
    "Protege las fuentes de agua en tu comunidad, son nuestro mayor tesoro.",
    "¡El agua que bebes hoy podría ser la misma que bebió un dinosaurio!",
    "El hielo es menos denso que el agua líquida, por eso flota maravillosamente.",
    "No uses cloro en exceso; daña gravemente ecosistemas cuando llega al río.",
    "Beber suficiente agua previene dolores de cabeza y reduce fatiga.",
    "Mantén limpia tu cisterna o tinaco para que tu agua se mantenga pura.",
    "Si ves una fuga en la calle, ¡repórtala inmediatamente a tu municipio!",
    "Fomenta el cuidado del agua en los niños. ¡Ellos protegerán el futuro!",
    "No laves tu banqueta con agua potable, utiliza el agua de la lavadora.",
    "Aprende dónde está la llave de paso de tu casa para evitar inundaciones.",
    "Cierra la llave mientras te afeitas y salva hasta 10 litros por vez.",
    "Aprovechar luz natural también ahorra aguan invertida en crear electricidad.",
    "No desperdicies agua en carnavales; juega responsablemente.",
    "El cuerpo humano sobrevive semanas sin comida, pero sólo días sin agua.",
    "Escuchar el sonido del agua fluyendo relaja la mente y el cuerpo.",
    "Recicla envases de plástico para que no tapen drenajes y ríos.",
    "Los arrecifes necesitan de agua oceánica clara y limpia para existir.",
    "Las aguas subterráneas nutren de agua potable al 50% de la población.",
    "Usa pinturas a base de agua y ecológicas en vez de productos tóxicos.",
    "Cada gota que ahorras hoy, es vida asegurada para el mañana.",
    "Instala sistemas duales de descarga en baños para cuidar cada litro.",
    "La sangre humana es 83% agua; transporta nutrientes vitales en ti.",
    "Producir un litro de leche requiere unos 1000 litros de agua en granja.",
    "El agua que no consumes tiene valor; sostiene nuestros santuarios naturales.",
    "Planta árboles para proteger ríos y evitar que se evaporen rápido.",
    "Un buen purificador en casa evita consumir miles de plásticos al año.",
    "Tener piel y cabello saludables depende completamente de la hidratación.",
    "Casi 80% del agua residual del mundo vuelve al ciclo sin ser limpiada.",
    "Cuida las áreas verdes de tu ciudad; ayudan a filtrar lluvia al subsuelo.",
    "Usar sal para quitar la nieve afecta la pureza del subsuelo al fundirse.",
    "Una gotita paciente es capaz de tallar cavernas enteras con los años.",
    "Enjuaga tu boca con solo un vasito de agua, ¡es suficiente y no desperdicias!",
    "Los árboles adultos pueden retener miles de litros tras una tormenta.",
    "Lavar ropa con agua fría es genial para la tela y no gasta energía extra.",
    "Limpia tu auto con cera seca o paños, ¡lucirá igual o mejor sin gastar agua!",
    "Compra boquillas de cierre automático para mangueras en el jardín.",
    "Barrer derrames de aceite con aserrín es mejor que limpiar con manguera.",
    "Las zonas de pasto esponjoso almacenan agua dulce. No las pavimentes todas.",
    "Reutilizar el agua en los parques ayuda a combatir el calor urbano.",
    "Las colillas en la calle terminan contaminando muchísimos litros en el mar.",
    "Hierve el agua dudosa antes de beberla para mantener a tu familia sana.",
    "Guarda los fertilizantes químicos muy lejos de las cañerías del patio.",
    "Riego por goteo salva tus platas de ahogarse y cuida hasta un 60% más.",
    "Evita usar la lavadora al mediodía para no sobrecalentar el ambiente.",
    "Tus consolas y celulares también tienen una enorme 'huella hídrica' detrás.",
    "Baña a tu perro sobre un césped seco para que se riegue a la vez.",
    "Sopas y caldos deliciosos pueden hacerse con el agua donde herviste verduras.",
    "Filtrar las 'aguas grises' de tu regadera ayuda a nutrir tu patio.",
    "Siembra flores amistosas con insectos para tener un microclima más sano.",
    "Una comida sin carne a la semana baja drásticamente el agua que consumes.",
    "Deja el pasto más alto en verano para que proteja sus raíces del sol.",
    "El agua purificada con la que te duchas costó esfuerzo limpiarla; apréciala.",
    "No llenes la tina al máximo; a la mitad tienes un excelente y relajante baño.",
    "100. ¡Felicidades por leer los tips! Eres vital en el rescate del agua del mundo.",
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: -5,
      end: 5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _currentTip = _waterTips[math.Random().nextInt(_waterTips.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade100, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Mascota Gotita
            _buildMascot(),
            const SizedBox(width: 15),
            // Burbuja de texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "💧 Goti-Tip!",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _currentTip,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMascot() {
    return SizedBox(
      width: 70,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Forma de gota
          Positioned(
            bottom: 5,
            child: Transform.rotate(
              angle: math.pi / 4, // 45 grados
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.lightBlueAccent, Colors.blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(
                      0,
                    ), // Punta de la gota orientada hacia arriba-izquierda (girada 45deg = recta hacia arriba)
                    topRight: Radius.circular(50),
                    bottomLeft: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                ),
              ),
            ),
          ),
          // Lentes 🤓
          const Positioned(
            top: 28,
            child: Text("👓", style: TextStyle(fontSize: 27)),
          ),
          // Sonrisa simple
          Positioned(
            top: 50,
            child: Container(
              width: 12,
              height: 5,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
            ),
          ),
          // iPad 📱 (lo carga en un costado)
          Positioned(
            top: 45,
            right: 0,
            child: Transform.rotate(
              angle: -0.2,
              child: const Text("📱", style: TextStyle(fontSize: 20)),
            ),
          ),
        ],
      ),
    );
  }
}
