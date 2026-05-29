import 'package:flutter/material.dart';
import 'dart:async';
import '../config/theme.dart';

enum PuzzleTutorialState { inicio, paso1, paso2, paso3, paso4, jugando }

class EcoPuzzleGame extends StatefulWidget {
  final void Function(int xp, int monedas)? onComplete;
  const EcoPuzzleGame({super.key, this.onComplete});

  @override
  State<EcoPuzzleGame> createState() => _EcoPuzzleGameState();
}

class _EcoPuzzleGameState extends State<EcoPuzzleGame> {
  PuzzleTutorialState _tutorial = PuzzleTutorialState.inicio;
  int _score = 0;
  int _timeLeft = 60;
  Timer? _timer;
  bool _running = false;

  int get _weekday => DateTime.now().weekday;

  String get _gameThemeName {
    switch (_weekday) {
      case 1: return 'Día de Orgánicos';
      case 3: return 'Día de Chatarra Electrónica y Pilas';
      case 5: return 'Día de Envases y Botellas';
      default: return 'Clasificación General Mixta';
    }
  }

  Color get _themeColor {
    switch (_weekday) {
      case 1: return AppTheme.green700;
      case 3: return const Color(0xFFE65100);
      case 5: return AppTheme.blue700;
      default: return AppTheme.red700;
    }
  }

  List<Map<String, dynamic>> _getThemeObjetosSource() {
    switch (_weekday) {
      case 1: // Lunes: Día de Orgánicos (Compostable Húmedo, Hojas/Ramas, Desecho Común)
        return [
          // Compostable Húmedo (organico_humedo)
          {'nombre': 'Cáscara de plátano', 'tipo': 'organico_humedo', 'emoji': '🍌'},
          {'nombre': 'Manzana mordida', 'tipo': 'organico_humedo', 'emoji': '🍎'},
          {'nombre': 'Restos de naranja', 'tipo': 'organico_humedo', 'emoji': '🍊'},
          {'nombre': 'Pepas de sandía', 'tipo': 'organico_humedo', 'emoji': '🍉'},
          {'nombre': 'Bolsita de té usada', 'tipo': 'organico_humedo', 'emoji': '🍵'},
          {'nombre': 'Carozo de durazno', 'tipo': 'organico_humedo', 'emoji': '🍑'},
          {'nombre': 'Cáscara de huevo', 'tipo': 'organico_humedo', 'emoji': '🥚'},
          {'nombre': 'Restos de lechuga', 'tipo': 'organico_humedo', 'emoji': '🥬'},
          {'nombre': 'Coronta de choclo', 'tipo': 'organico_humedo', 'emoji': '🌽'},
          // Hojas y Ramas Secas (organico_seco)
          {'nombre': 'Hojas secas', 'tipo': 'organico_seco', 'emoji': '🍂'},
          {'nombre': 'Pan duro', 'tipo': 'organico_seco', 'emoji': '🍞'},
          {'nombre': 'Ramas secas', 'tipo': 'organico_seco', 'emoji': '🪵'},
          {'nombre': 'Aserrín limpio', 'tipo': 'organico_seco', 'emoji': '🪵'},
          // Desecho Común (inorganico)
          {'nombre': 'Envoltura dulce', 'tipo': 'inorganico', 'emoji': '🍬'},
          {'nombre': 'Plástico sucio', 'tipo': 'inorganico', 'emoji': '🛍️'},
          {'nombre': 'Pañal desechable', 'tipo': 'inorganico', 'emoji': '🚼'},
          {'nombre': 'Papel higiénico', 'tipo': 'inorganico', 'emoji': '🧻'},
          {'nombre': 'Mascarilla', 'tipo': 'inorganico', 'emoji': '😷'},
        ];
      case 3: // Miércoles: Día de Chatarra Electrónica y Pilas (Pilas, Equipos, Desecho Común)
        return [
          // Pilas y Baterías (pilas)
          {'nombre': 'Pilas AA sulfatadas', 'tipo': 'pilas', 'emoji': '🔋'},
          {'nombre': 'Pila de botón usada', 'tipo': 'pilas', 'emoji': '🔋'},
          {'nombre': 'Batería de litio', 'tipo': 'pilas', 'emoji': '🔋'},
          // Equipos Electrónicos (electronico)
          {'nombre': 'Cable de carga roto', 'tipo': 'electronico', 'emoji': '🔌'},
          {'nombre': 'Control gamer roto', 'tipo': 'electronico', 'emoji': '🎮'},
          {'nombre': 'Audífonos viejos', 'tipo': 'electronico', 'emoji': '🎧'},
          {'nombre': 'Mouse de PC malo', 'tipo': 'electronico', 'emoji': '🖱️'},
          {'nombre': 'Calculadora rota', 'tipo': 'electronico', 'emoji': '🧮'},
          {'nombre': 'Ampolleta quemada', 'tipo': 'electronico', 'emoji': '💡'},
          {'nombre': 'Radio vieja', 'tipo': 'electronico', 'emoji': '📻'},
          {'nombre': 'Teléfono antiguo', 'tipo': 'electronico', 'emoji': '☎️'},
          // Desecho Común (inorganico)
          {'nombre': 'Envoltura dulce', 'tipo': 'inorganico', 'emoji': '🍬'},
          {'nombre': 'Plástico sucio', 'tipo': 'inorganico', 'emoji': '🛍️'},
          {'nombre': 'Pañal desechable', 'tipo': 'inorganico', 'emoji': '🚼'},
          {'nombre': 'Papel higiénico', 'tipo': 'inorganico', 'emoji': '🧻'},
          {'nombre': 'Mascarilla', 'tipo': 'inorganico', 'emoji': '😷'},
        ];
      case 5: // Viernes: Envases y Botellas (Plástico/Vidrio, Papel/Cartón, Inorgánico)
        return [
          // Plástico/Vidrio (reciclable_envase)
          {'nombre': 'Botella plástica', 'tipo': 'reciclable_envase', 'emoji': '🧴'},
          {'nombre': 'Lata de refresco', 'tipo': 'reciclable_envase', 'emoji': '🥤'},
          {'nombre': 'Botella de vidrio', 'tipo': 'reciclable_envase', 'emoji': '🍾'},
          {'nombre': 'Pote de yogur', 'tipo': 'reciclable_envase', 'emoji': '🥣'},
          {'nombre': 'Envase de champú', 'tipo': 'reciclable_envase', 'emoji': '🧴'},
          {'nombre': 'Tarro de atún vacío', 'tipo': 'reciclable_envase', 'emoji': '🥫'},
          // Papel/Cartón (reciclable_papel)
          {'nombre': 'Caja de leche Tetra Pak', 'tipo': 'reciclable_papel', 'emoji': '🥛'},
          {'nombre': 'Cajita de jugo', 'tipo': 'reciclable_papel', 'emoji': '🧃'},
          {'nombre': 'Caja de cereal', 'tipo': 'reciclable_papel', 'emoji': '📦'},
          {'nombre': 'Periódico viejo', 'tipo': 'reciclable_papel', 'emoji': '📰'},
          {'nombre': 'Cuaderno usado', 'tipo': 'reciclable_papel', 'emoji': '📓'},
          {'nombre': 'Revista vieja', 'tipo': 'reciclable_papel', 'emoji': '📖'},
          // Desecho Común (inorganico)
          {'nombre': 'Envoltura dulce', 'tipo': 'inorganico', 'emoji': '🍬'},
          {'nombre': 'Plástico sucio', 'tipo': 'inorganico', 'emoji': '🛍️'},
          {'nombre': 'Pañal desechable', 'tipo': 'inorganico', 'emoji': '🚼'},
          {'nombre': 'Papel higiénico', 'tipo': 'inorganico', 'emoji': '🧻'},
          {'nombre': 'Mascarilla', 'tipo': 'inorganico', 'emoji': '😷'},
        ];
      default: // Otros días (General)
        return [
          // Orgánico (organico)
          {'nombre': 'Cáscara de plátano', 'tipo': 'organico', 'emoji': '🍌'},
          {'nombre': 'Manzana mordida', 'tipo': 'organico', 'emoji': '🍎'},
          {'nombre': 'Hojas secas', 'tipo': 'organico', 'emoji': '🍂'},
          {'nombre': 'Pan duro', 'tipo': 'organico', 'emoji': '🍞'},
          // Reciclable (reciclable)
          {'nombre': 'Lata de refresco', 'tipo': 'reciclable', 'emoji': '🥤'},
          {'nombre': 'Botella de vidrio', 'tipo': 'reciclable', 'emoji': '🍾'},
          {'nombre': 'Caja de cereal', 'tipo': 'reciclable', 'emoji': '📦'},
          {'nombre': 'Periódico viejo', 'tipo': 'reciclable', 'emoji': '📰'},
          // Inorgánico (inorganico)
          {'nombre': 'Envoltura dulce', 'tipo': 'inorganico', 'emoji': '🍬'},
          {'nombre': 'Plástico sucio', 'tipo': 'inorganico', 'emoji': '🛍️'},
          {'nombre': 'Cable de carga roto', 'tipo': 'inorganico', 'emoji': '🔌'},
          {'nombre': 'Pila gastada', 'tipo': 'inorganico', 'emoji': '🔋'},
          {'nombre': 'Papel higiénico', 'tipo': 'inorganico', 'emoji': '🧻'},
        ];
    }
  }

  List<Map<String, dynamic>> _objetos = [];
  Map<String, Color?> _feedback = {};

  void _startGame() {
    setState(() {
      _tutorial = PuzzleTutorialState.jugando;
      _running = true;
      _score = 0;
      _timeLeft = 60;
      _feedback = {};
      _objetos = List.from(_getThemeObjetosSource())..shuffle();
      _objetos = _objetos.asMap().entries.map((e) => {
        'id': e.key,
        'nombre': e.value['nombre'],
        'tipo': e.value['tipo'],
        'emoji': e.value['emoji'],
        'clasificado': false,
      }).toList();
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_running) { t.cancel(); return; }
      setState(() {
        if (_timeLeft > 0) _timeLeft--;
        if (_timeLeft == 0) _running = false;
      });
    });
  }

  void _classify(int objId, String binType) {
    final obj = _objetos.firstWhere((o) => o['id'] == objId);
    if (obj['clasificado'] == true) return;
    final correct = obj['tipo'] == binType;

    obj['clasificado'] = true;
    if (correct) _score++;
    _feedback[binType] = correct ? Colors.green : Colors.red;

    setState(() {});
    Future.delayed(const Duration(milliseconds: 600), () {
      _feedback[binType] = null;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_running && _timeLeft == 60) {
      return _buildTutorial();
    }

    final restantes = _objetos.where((o) => !o['clasificado']).toList();
    final terminado = _timeLeft == 0 || restantes.isEmpty;

    if (terminado) {
      return _buildResult();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Restantes: ${restantes.length}', style: TextStyle(color: _themeColor, fontWeight: FontWeight.w700, fontSize: 13)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: _themeColor, borderRadius: BorderRadius.circular(12)),
              child: Text('${_timeLeft}s', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (restantes.isNotEmpty)
          Center(
            child: Draggable<int>(
              data: restantes.first['id'],
              feedback: _buildItemCard(restantes.first, true, isFeedback: true),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _buildItemCard(restantes.first, false),
              ),
              child: _buildItemCard(restantes.first, false),
            ),
          ),
        const SizedBox(height: 16),
        Text('Arrastra al basurero correcto', style: TextStyle(color: _themeColor, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _buildThemeBins(),
      ],
    );
  }

  Widget _buildThemeBins() {
    final day = _weekday;
    if (day == 1) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _binDragTarget('organico_humedo', 'Húmedo', 'Compostable Húmedo', AppTheme.green500),
          _binDragTarget('organico_seco', 'Seco', 'Hojas y Ramas', const Color(0xFF8D6E63)), // Marrón (Brown)
          _binDragTarget('inorganico', 'Rechazo', 'Desecho Común', Colors.grey.shade800),
        ],
      );
    } else if (day == 3) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _binDragTarget('pilas', 'Pilas', 'Pilas y Baterías', Colors.red.shade700),
          _binDragTarget('electronico', 'Equipos', 'Equipos Electrónicos', const Color(0xFF1A237E)), // Azul Navy
          _binDragTarget('inorganico', 'Rechazo', 'Desecho Común', Colors.grey.shade800),
        ],
      );
    } else if (day == 5) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _binDragTarget('reciclable_envase', 'Envases', 'Plástico/Vidrio', Colors.cyan.shade600), // Celeste HSL
          _binDragTarget('reciclable_papel', 'Papel', 'Papel/Cartón', AppTheme.blue700),
          _binDragTarget('inorganico', 'Rechazo', 'Inorgánico', Colors.grey.shade800),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _binDragTarget('organico', 'O', 'Orgánico', AppTheme.green500),
          _binDragTarget('reciclable', 'R', 'Reciclable', AppTheme.blue700),
          _binDragTarget('inorganico', 'I', 'Inorgánico', Colors.grey.shade800),
        ],
      );
    }
  }

  Widget _buildItemCard(Map<String, dynamic> obj, bool isDragging, {bool isFeedback = false}) {
    final card = Container(
      width: 110, height: 110,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _themeColor.withAlpha(isDragging ? 150 : 77), width: isDragging ? 3 : 1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDragging ? [BoxShadow(color: _themeColor.withAlpha(50), blurRadius: 10, spreadRadius: 2)] : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(obj['emoji'], style: const TextStyle(fontSize: 38, decoration: TextDecoration.none)),
          const SizedBox(height: 4),
          Expanded(
            child: Center(
              child: Text(obj['nombre'], style: TextStyle(color: _themeColor, fontSize: 10, fontWeight: FontWeight.w800, decoration: TextDecoration.none, height: 1.1), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
    
    return isFeedback ? Material(color: Colors.transparent, child: card) : card;
  }

  Widget _binDragTarget(String tipo, String label, String name, Color color) {
    final fb = _feedback[tipo];
    return DragTarget<int>(
      onAcceptWithDetails: (details) {
        _classify(details.data, tipo);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 95,
              height: 100,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isHovering ? 90 : 70,
                height: isHovering ? 95 : 78,
                margin: EdgeInsets.symmetric(
                  horizontal: isHovering ? 2 : 12,
                  vertical: isHovering ? 2 : 11,
                ),
                decoration: BoxDecoration(
                  color: fb ?? color,
                  borderRadius: BorderRadius.circular(isHovering ? 8 : 16),
                  boxShadow: isHovering ? [BoxShadow(color: color.withAlpha(100), blurRadius: 15, spreadRadius: 2)] : [],
                  border: isHovering ? Border.all(color: Colors.white, width: 3) : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: isHovering ? (Matrix4.translationValues(8, -8, 0)..rotateZ(0.3)) : Matrix4.identity(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 12, height: 4, decoration: BoxDecoration(color: fb != null ? Colors.white : (isHovering ? Colors.white : Colors.white70), borderRadius: const BorderRadius.vertical(top: Radius.circular(3)))),
                          Container(width: 38, height: 6, decoration: BoxDecoration(color: fb != null ? Colors.white : (isHovering ? Colors.white : Colors.white70), borderRadius: BorderRadius.circular(3))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isHovering ? 32 : 28,
                      height: isHovering ? 36 : 30,
                      decoration: BoxDecoration(
                        color: fb != null ? Colors.white : (isHovering ? Colors.white : Colors.white70),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(name, style: TextStyle(color: color, fontSize: 12, fontWeight: isHovering ? FontWeight.w900 : FontWeight.w700)),
          ],
        );
      },
    );
  }

  Widget _buildTutorial() {
    final day = _weekday;
    if (day == 1) {
      switch (_tutorial) {
        case PuzzleTutorialState.inicio:
          return _tutorialCard('¡Bienvenido al Eco-Puzzle!', 'Misión de hoy: $_gameThemeName.\nClasifica orgánicos secos y húmedos.',
            'Comenzar Tutorial', _themeColor, () => setState(() => _tutorial = PuzzleTutorialState.paso1),
            secondaryLabel: 'Omitir (ya sé jugar)', onSecondary: _startGame);
        case PuzzleTutorialState.paso1:
          return _tutorialCard('🟢 Compostable Húmedo', 'Residuos húmedos de cocina.\nEj: cáscaras de plátano 🍌, manzana 🍎, lechuga 🥬, té 🍵, huevo 🥚.',
            'Siguiente: Hojas y Ramas', AppTheme.green500, () => setState(() => _tutorial = PuzzleTutorialState.paso2));
        case PuzzleTutorialState.paso2:
          return _tutorialCard('🟫 Hojas y Ramas Secas', 'Residuos orgánicos secos de jardín y otros.\nEj: hojas secas 🍂, ramas 🪵, aserrín 🪵, pan duro 🍞.',
            'Siguiente: Desecho Común', const Color(0xFF8D6E63), () => setState(() => _tutorial = PuzzleTutorialState.paso3));
        case PuzzleTutorialState.paso3:
          return _tutorialCard('⚫ Desecho Común', 'No se compostan ni reciclan.\nEj: envoltorios de dulce 🍬, bolsas plásticas sucias 🛍️, pañales 🚼, papel higiénico 🧻.',
            'Siguiente: Cómo jugar', Colors.grey.shade800, () => setState(() => _tutorial = PuzzleTutorialState.paso4));
        case PuzzleTutorialState.paso4:
          return _tutorialCard('🎯 Cómo jugar', 'Arrastra los objetos al basurero correspondiente antes de que se acabe el tiempo (60s).',
            '¡Comenzar a Jugar!', _themeColor, _startGame);
        default:
          return const SizedBox.shrink();
      }
    } else if (day == 3) {
      switch (_tutorial) {
        case PuzzleTutorialState.inicio:
          return _tutorialCard('¡Bienvenido al Eco-Puzzle!', 'Misión de hoy: $_gameThemeName.\nClasifica pilas y chatarra electrónica.',
            'Comenzar Tutorial', _themeColor, () => setState(() => _tutorial = PuzzleTutorialState.paso1),
            secondaryLabel: 'Omitir (ya sé jugar)', onSecondary: _startGame);
        case PuzzleTutorialState.paso1:
          return _tutorialCard('🔴 Pilas y Baterías', 'Pilas AA/AAA y baterías usadas.\nEj: pilas sulfatadas 🔋, pila de botón usada 🔋.',
            'Siguiente: Equipos', Colors.red.shade700, () => setState(() => _tutorial = PuzzleTutorialState.paso2));
        case PuzzleTutorialState.paso2:
          return _tutorialCard('🔵 Equipos Electrónicos', 'Dispositivos, accesorios y periféricos dañados.\nEj: cables rotos 🔌, audífonos viejos 🎧, control gamer roto 🎮, mouse dañado 🖱️.',
            'Siguiente: Desecho Común', const Color(0xFF1A237E), () => setState(() => _tutorial = PuzzleTutorialState.paso3));
        case PuzzleTutorialState.paso3:
          return _tutorialCard('⚫ Desecho Común', 'Residuos no reciclables.\nEj: envoltorios 🍬, plásticos sucios 🛍️, pañales 🚼, papel higiénico 🧻.',
            'Siguiente: Cómo jugar', Colors.grey.shade800, () => setState(() => _tutorial = PuzzleTutorialState.paso4));
        case PuzzleTutorialState.paso4:
          return _tutorialCard('🎯 Cómo jugar', 'Arrastra los objetos al basurero correspondiente antes de que se acabe el tiempo (60s).',
            '¡Comenzar a Jugar!', _themeColor, _startGame);
        default:
          return const SizedBox.shrink();
      }
    } else if (day == 5) {
      switch (_tutorial) {
        case PuzzleTutorialState.inicio:
          return _tutorialCard('¡Bienvenido al Eco-Puzzle!', 'Misión de hoy: $_gameThemeName.\nClasifica plásticos, vidrio, papel y cartón.',
            'Comenzar Tutorial', _themeColor, () => setState(() => _tutorial = PuzzleTutorialState.paso1),
            secondaryLabel: 'Omitir (ya sé jugar)', onSecondary: _startGame);
        case PuzzleTutorialState.paso1:
          return _tutorialCard('💎 Plástico/Vidrio (Celeste)', 'Envases de plástico, vidrio o metal.\nEj: botellas plásticas 🧴, latas de aluminio 🥤, botella de vidrio 🍾, potes de yogur 🥣.',
            'Siguiente: Papel/Cartón', Colors.cyan.shade600, () => setState(() => _tutorial = PuzzleTutorialState.paso2));
        case PuzzleTutorialState.paso2:
          return _tutorialCard('📘 Papel/Cartón (Azul)', 'Materiales limpios de celulosa.\nEj: cajas de leche Tetra Pak 🥛, cajitas de jugo 🧃, caja de cereal 📦, cuadernos usados 📓.',
            'Siguiente: Desecho Común', AppTheme.blue700, () => setState(() => _tutorial = PuzzleTutorialState.paso3));
        case PuzzleTutorialState.paso3:
          return _tutorialCard('⚫ Desecho Común', 'Materiales no recuperables o sucios.\nEj: envolturas de golosinas 🍬, bolsas plásticas sucias 🛍️, pañales 🚼, papel higiénico 🧻.',
            'Siguiente: Cómo jugar', Colors.grey.shade800, () => setState(() => _tutorial = PuzzleTutorialState.paso4));
        case PuzzleTutorialState.paso4:
          return _tutorialCard('🎯 Cómo jugar', 'Arrastra los objetos al basurero correspondiente antes de que se acabe el tiempo (60s).',
            '¡Comenzar a Jugar!', _themeColor, _startGame);
        default:
          return const SizedBox.shrink();
      }
    } else {
      // General
      switch (_tutorial) {
        case PuzzleTutorialState.inicio:
          return _tutorialCard('¡Bienvenido al Eco-Puzzle!', 'Aprende a clasificar residuos de forma divertida.',
            'Comenzar Tutorial', _themeColor, () => setState(() => _tutorial = PuzzleTutorialState.paso1),
            secondaryLabel: 'Omitir (ya sé jugar)', onSecondary: _startGame);
        case PuzzleTutorialState.paso1:
          return _tutorialCard('🟢 Paso 1: Orgánico', 'Residuos de origen natural que se descomponen.\nEj: Cáscaras, restos de comida.',
            'Siguiente: Reciclable', AppTheme.green500, () => setState(() => _tutorial = PuzzleTutorialState.paso2));
        case PuzzleTutorialState.paso2:
          return _tutorialCard('🔵 Paso 2: Reciclable', 'Se puede reutilizar si está limpio.\nEj: Vidrio, latas, plástico limpio.',
            'Siguiente: Inorgánico', AppTheme.blue700, () => setState(() => _tutorial = PuzzleTutorialState.paso3));
        case PuzzleTutorialState.paso3:
          return _tutorialCard('⚫ Paso 3: Inorgánico', 'No se recicla ni se descompone fácilmente.\nEj: Papel higiénico, plástico sucio, esponjas.',
            'Siguiente: Mecánicas', Colors.grey.shade800, () => setState(() => _tutorial = PuzzleTutorialState.paso4));
        case PuzzleTutorialState.paso4:
          return _tutorialCard('🎯 Paso 4: Cómo jugar', 'Arrastra los objetos al basurero correcto antes de que acabe el tiempo (60s).',
            '¡Comenzar a Jugar!', _themeColor, _startGame);
        default:
          return const SizedBox.shrink();
      }
    }
  }

  Widget _tutorialCard(String title, String desc, String btnText, Color color, VoidCallback onTap,
      {String? secondaryLabel, VoidCallback? onSecondary}) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Text(title, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withAlpha(77), width: 2),
          ),
          child: Text(desc, style: TextStyle(color: color, fontSize: 13), textAlign: TextAlign.center),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(btnText, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ),
        if (secondaryLabel != null) ...[
          const SizedBox(height: 8),
          TextButton(onPressed: onSecondary, child: Text(secondaryLabel, style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
        ],
      ],
    );
  }

  Widget _buildResult() {
    final maxScore = _objetos.length;
    final xp = (_score / maxScore * 120).round();
    final monedas = (_score / maxScore * 20).round();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_score == maxScore ? 'PERFECTO' : _score >= maxScore / 2 ? 'BIEN' : 'CASI', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.green700)),
          const SizedBox(height: 8),
          Text('Clasificaste $_score de $maxScore', style: const TextStyle(color: AppTheme.green500, fontSize: 14)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _resultStat('+$xp XP', 'Para nivel', AppTheme.textDark),
              const SizedBox(width: 24, height: 40, child: VerticalDivider(color: AppTheme.green200)),
              _resultStat('+$monedas monedas', 'Para canjes', AppTheme.amber400),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.onComplete != null)
            ElevatedButton(
              onPressed: () => widget.onComplete!(xp, monedas),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.green700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Reclamar y Volver', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
        ],
      ),
    );
  }

  Widget _resultStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: AppTheme.textLight, fontSize: 11)),
      ],
    );
  }
}
