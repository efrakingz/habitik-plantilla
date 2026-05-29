import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../constants/eco_words.dart';
import 'shared_ui.dart';

class WordleChallenge extends StatefulWidget {
  final VoidCallback onBack;
  final SubmitChallengeFunc onSubmit;

  const WordleChallenge({super.key, required this.onBack, required this.onSubmit});

  @override
  State<WordleChallenge> createState() => _WordleChallengeState();
}

class _WordleChallengeState extends State<WordleChallenge> {
  String _wordleTarget = '';
  final List<String> _wordleGuesses = List.generate(6, (_) => '');
  int _wordleAttempt = 0;
  String _wordleCurrent = '';
  bool _wordleFinished = false;
  bool _wordleWon = false;
  final Map<String, Color> _keyboardColors = {};
  int _wordleHintsUsed = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initWordle();
  }

  void _initWordle() {
    if (_wordleTarget.isNotEmpty) return;
    final now = DateTime.now();
    final seed = (now.year * 365 + now.month * 31 + now.day) % ecoWords.length;
    _wordleTarget = ecoWords[seed].toUpperCase();
    _wordleGuesses.fillRange(0, 6, '');
    _wordleAttempt = 0;
    _wordleCurrent = '';
    _wordleFinished = false;
    _wordleWon = false;
    _keyboardColors.clear();
    _wordleHintsUsed = 0;
  }

  Future<void> _useWordleHint() async {
    if (_wordleFinished) return;

    if (_wordleHintsUsed >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya has usado el límite de 3 pistas en esta partida.', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.red700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final userCoins = authProvider.profile?.monedas ?? 0;

    if (userCoins < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes suficientes monedas. Cada pista cuesta 1 🪙.', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.red700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lightbulb_outline, color: AppTheme.amber500),
            SizedBox(width: 8),
            Text('¿Usar pista?', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          ],
        ),
        content: const Text(
          'Te costará 1 moneda (🪙) revelar una letra de la palabra.',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.green700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Usar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await authProvider.deductCoins(1);
      
      if (!mounted) return;

      List<int> incorrectIndices = [];
      for (int i = 0; i < _wordleTarget.length; i++) {
        bool correct = false;
        for (int r = 0; r < _wordleAttempt; r++) {
          if (_wordleGuesses[r].length > i && _wordleGuesses[r][i] == _wordleTarget[i]) {
            correct = true;
            break;
          }
        }
        if (!correct) {
          incorrectIndices.add(i);
        }
      }

      String revealedLetter = '';
      int position = 0;
      if (incorrectIndices.isNotEmpty) {
        final rand = Random();
        position = incorrectIndices[rand.nextInt(incorrectIndices.length)];
        revealedLetter = _wordleTarget[position];
      } else {
        final rand = Random();
        position = rand.nextInt(_wordleTarget.length);
        revealedLetter = _wordleTarget[position];
      }

      setState(() {
        _wordleHintsUsed++;
        _keyboardColors[revealedLetter] = AppTheme.amber500;
        _isSubmitting = false;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lightbulb, color: AppTheme.amber500),
              SizedBox(width: 8),
              Text('¡Pista revelada!', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            ],
          ),
          content: Text(
            'La palabra ecológica contiene la letra "$revealedLetter" en la posición ${position + 1}.\n\n'
            'Se ha destacado de color naranja en tu teclado.',
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.green700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Entendido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar la pista: ${e.toString()}', style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: AppTheme.red700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<Color> _getGuessColors(String guess) {
    final colors = List.generate(guess.length, (_) => Colors.grey.shade400);
    final targetLetterCounts = <String, int>{};
    for (var char in _wordleTarget.split('')) {
      targetLetterCounts[char] = (targetLetterCounts[char] ?? 0) + 1;
    }
    
    for (int i = 0; i < guess.length; i++) {
      final letter = guess[i];
      if (letter == _wordleTarget[i]) {
        colors[i] = AppTheme.green600;
        targetLetterCounts[letter] = targetLetterCounts[letter]! - 1;
      }
    }
    
    for (int i = 0; i < guess.length; i++) {
      final letter = guess[i];
      if (colors[i] != AppTheme.green600) {
        if (targetLetterCounts.containsKey(letter) && targetLetterCounts[letter]! > 0) {
          colors[i] = AppTheme.amber500;
          targetLetterCounts[letter] = targetLetterCounts[letter]! - 1;
        }
      }
    }
    
    return colors;
  }

  void _updateKeyboardColors(String guess, List<Color> colors) {
    for (int i = 0; i < guess.length; i++) {
      final letter = guess[i];
      final col = colors[i];
      final current = _keyboardColors[letter];
      if (current == AppTheme.green600) {
      } else if (current == AppTheme.amber500 && col == AppTheme.green600) {
        _keyboardColors[letter] = col;
      } else if (current == null || (current != AppTheme.green600 && current != AppTheme.amber500)) {
        _keyboardColors[letter] = col;
      }
    }
  }

  String _getEducationalTip(String word) {
    final tips = {
      'AGUA': 'El agua es un recurso vital escaso. Reducir tu ducha a 5 minutos ahorra hasta 100 litros al día.',
      'AIRE': 'Mantener el aire limpio depende de nuestras emisiones. Privilegia caminar o usar bicicleta.',
      'HOJA': 'Las hojas secas son excelentes para la capa seca del compost, aportando carbono esencial.',
      'RAMA': 'Las ramas secas picadas estructuran el compostaje casero facilitando la oxigenación.',
      'VIDA': 'Cuidar el medio ambiente es proteger toda forma de vida y preservar la biodiversidad.',
      'SOLAR': 'La energía solar es limpia, inagotable y reduce a cero la huella de carbono por electricidad.',
      'POZO': 'Los pozos de agua subterránea deben ser monitoreados para evitar su sobreexplotación.',
      'LAGO': 'Los lagos son termorreguladores naturales y el hábitat de valiosos ecosistemas locales.',
      'CLIMA': 'El cambio climático amenaza la estabilidad del planeta. Cada pequeño ahorro cuenta.',
      'VERDE': 'El color verde simboliza el compromiso con el medio ambiente y la fotosíntesis vital.',
      'ARBOL': 'Un solo árbol maduro puede absorber hasta 22 kg de CO2 al año y liberar oxígeno vital.',
      'SUELO': 'Un suelo sano y orgánico es capaz de retener más agua y almacenar carbono de la atmósfera.',
      'FLORA': 'La flora nativa chilena está adaptada a la sequía y requiere mucha menos agua para su riego.',
      'FAUNA': 'La fauna silvestre mantiene el equilibrio ecológico dispersando semillas y polinizando.',
      'CABLE': 'Los cables enchufados sin uso generan "consumo vampiro", desperdiciando energía silenciosamente.',
      'PAPEL': 'Reciclar 1 tonelada de papel evita la tala de 17 árboles y ahorra miles de litros de agua.',
      'RIEGO': 'El riego nocturno evita la evaporación por calor, aprovechando el 95% del agua utilizada.',
      'FOCO': 'Cambiar ampolletas tradicionales por focos LED reduce el consumo eléctrico de iluminación en un 80%.',
      'PILAS': 'Una sola pila común puede contaminar 600.000 litros de agua si se desecha en la basura común.',
      'HOGAR': 'Un hogar sustentable implementa hábitos diarios de ahorro de agua, luz y reciclaje.',
      'DUCHA': 'Tomar duchas breves de 5 minutos es la acción individual que más agua ahorra en el hogar.',
      'GRIFO': 'Un grifo goteando desperdicia hasta 30 litros de agua diarios. ¡Repáralo a tiempo!',
      'REUSO': 'Reutilizar el agua de lavado de frutas para regar plantas ahorra este recurso vital.',
      'BOSQUE': 'Los bosques nativos protegen las cuencas de agua y actúan como grandes pulmones verdes.',
      'BASURA': 'Reducir la basura generada comienza rechazando plásticos de un solo uso y compostando.',
      'VIDRIO': 'El vidrio es 100% reciclable infinitas veces. Al reciclarlo, ahorramos arena y energía.',
      'CARTON': 'El cartón reciclado reduce en un 74% la contaminación del aire en comparación con el nuevo.',
      'AHORRO': 'El ahorro de recursos no solo ayuda al planeta, sino que alivia el presupuesto familiar.',
      'PLANTAS': 'Las plantas purifican el aire de interiores y ayudan a regular la humedad natural.',
      'RECICLA': 'El reciclaje convierte residuos en nuevas materias primas, reduciendo la explotación natural.',
      'HUMEDAL': 'Los humedales filtran el agua dulce, controlan inundaciones y albergan gran biodiversidad.',
      'MEDIDOR': 'Monitorear el medidor de agua nos permite detectar fugas invisibles en el WC o cañerías.',
      'BOLETA': 'Revisar el gráfico histórico de tu boleta te ayuda a evaluar si tus hábitos de ahorro funcionan.',
      'SECADORA': 'La secadora eléctrica es uno de los artefactos que más energía consume. Seca al sol siempre que puedas.',
      'ECOLOGIA': 'Es la ciencia que estudia la interacción de los seres vivos con su entorno físico.',
      'PLASTICO': 'El plástico tarda hasta 500 años en degradarse. Evita botellas desechables y usa reutilizables.',
      'COMPOST': 'El compostaje transforma residuos de alimentos en abono rico en nutrientes para tu jardín.',
      'RECHAZO': 'Los residuos no reciclables ni compostables deben ir a la basura común sin contaminar lo limpio.',
      'HERVIDO': 'Usar el hervidor eléctrico consume mucha potencia. Calienta solo el agua que vas a tomar.',
      'VAMPIROS': 'Los vampiros de energía son los aparatos en standby. Desenchúfalos y ahorra hasta un 10% de luz.',
    };
    return tips[word] ?? 'Esta palabra se relaciona con la preservación ambiental, el ahorro de energía o agua, y los buenos hábitos ecológicos de tu familia.';
  }

  void _handleWordleKeyPress(String key) {
    if (_wordleFinished) return;
    
    if (key == 'BORRAR') {
      if (_wordleCurrent.isNotEmpty) {
        setState(() {
          _wordleCurrent = _wordleCurrent.substring(0, _wordleCurrent.length - 1);
        });
      }
    } else if (key == 'ENVIAR') {
      if (_wordleCurrent.length == _wordleTarget.length) {
        final guess = _wordleCurrent.toUpperCase();
        setState(() {
          _wordleGuesses[_wordleAttempt] = guess;
          final colors = _getGuessColors(guess);
          _updateKeyboardColors(guess, colors);
          
          if (guess == _wordleTarget) {
            _wordleFinished = true;
            _wordleWon = true;
          } else {
            _wordleAttempt++;
            _wordleCurrent = '';
            if (_wordleAttempt >= 6) {
              _wordleFinished = true;
              _wordleWon = false;
            }
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('La palabra debe tener ${_wordleTarget.length} letras'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } else {
      if (_wordleCurrent.length < _wordleTarget.length) {
        setState(() {
          _wordleCurrent += key;
        });
      }
    }
  }

  Widget _buildWordleKeyboard() {
    final rows = [
      ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'Ñ'],
      ['ENVIAR', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'BORRAR'],
    ];
    
    return Column(
      children: rows.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            final isSpecial = key == 'ENVIAR' || key == 'BORRAR';
            final width = isSpecial ? 54.0 : 28.0;
            final bg = _keyboardColors[key] ?? Colors.grey.shade200;
            final textCol = bg == Colors.grey.shade200 ? AppTheme.textDark : Colors.white;
            
            return Container(
              margin: const EdgeInsets.all(2.0),
              height: 40,
              width: width,
              child: ElevatedButton(
                onPressed: () => _handleWordleKeyPress(key),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: bg,
                  foregroundColor: textCol,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                ),
                child: Text(
                  key == 'BORRAR' ? '⌫' : (key == 'ENVIAR' ? '✔' : key),
                  style: TextStyle(
                    fontSize: isSpecial ? 12 : 14, 
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finished = _wordleFinished;
    final won = _wordleWon;
    final authProvider = context.watch<AuthProvider>();
    final monedas = authProvider.profile?.monedas ?? 0;
    
    return ChallengeShell(
      color: AppTheme.green700,
      title: '🔤 Eco-Wordle del Día',
      onClose: () {
        widget.onBack();
      },
      extra: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('🪙 ', style: TextStyle(fontSize: 14)),
                Text(
                  '$monedas',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (!finished) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isSubmitting ? null : _useWordleHint,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _wordleHintsUsed >= 3 
                      ? Colors.white.withValues(alpha: 0.05) 
                      : AppTheme.amber400.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _wordleHintsUsed >= 3 
                        ? Colors.white.withValues(alpha: 0.1) 
                        : AppTheme.amber400,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _wordleHintsUsed >= 3 ? Icons.lightbulb_outline : Icons.lightbulb,
                      color: _wordleHintsUsed >= 3 ? Colors.white60 : AppTheme.amber400,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${3 - _wordleHintsUsed}',
                      style: TextStyle(
                        color: _wordleHintsUsed >= 3 ? Colors.white60 : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      child: Column(
        children: [
          Text(
            'Adivina la palabra ecológica de ${_wordleTarget.length} letras.',
            style: const TextStyle(color: AppTheme.textLight, fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(6, (r) {
                    final guess = _wordleGuesses[r];
                    final isCurrentRow = r == _wordleAttempt;
                    
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_wordleTarget.length, (c) {
                        String char = '';
                        Color cellBg = Colors.white;
                        Color borderCol = Colors.grey.shade300;
                        Color textCol = AppTheme.textDark;
                        
                        if (isCurrentRow) {
                          if (c < _wordleCurrent.length) {
                            char = _wordleCurrent[c];
                            borderCol = AppTheme.green500;
                          }
                        } else {
                          if (guess.isNotEmpty) {
                            char = guess[c];
                            final colors = _getGuessColors(guess);
                            cellBg = colors[c];
                            borderCol = Colors.transparent;
                            textCol = Colors.white;
                          }
                        }
                        
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.all(4),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: cellBg,
                            border: Border.all(color: borderCol, width: 2),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: isCurrentRow && c == _wordleCurrent.length - 1
                              ? [BoxShadow(color: AppTheme.green500.withAlpha(50), blurRadius: 4)]
                              : [],
                          ),
                          child: Center(
                            child: Text(
                              char,
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.w900,
                                color: textCol,
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (finished) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: won ? AppTheme.green50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: won ? AppTheme.green300 : Colors.red.shade300),
              ),
              child: Column(
                children: [
                  Text(
                    won ? '🎉 ¡Felicidades, ganaste!' : '😢 No lograste adivinar. La palabra era $_wordleTarget',
                    style: TextStyle(
                      color: won ? AppTheme.green700 : Colors.red.shade700, 
                      fontWeight: FontWeight.w900, 
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: won ? AppTheme.green200 : Colors.red.shade200),
                    ),
                    child: Text(
                      _getEducationalTip(_wordleTarget),
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RewardStat(value: won ? '+50 XP' : '+0 XP', label: 'Para nivel', color: AppTheme.textDark),
                      const SizedBox(width: 24, height: 30, child: VerticalDivider(color: Colors.grey)),
                      RewardStat(value: won ? '+5 🪙' : '+0 🪙', label: 'Para canjes', color: AppTheme.amber400),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final xp = won ? 50 : 0;
                final monedas = won ? 5 : 0;
                
                await widget.onSubmit(
                  'wordle', 
                  'Eco-Wordle del Día', 
                  xp, 
                  monedas, 
                  ['Palabra: $_wordleTarget', 'Intentos: $_wordleAttempt', 'Resultado: ${won ? "Ganó" : "Perdió"}'], 
                  false, 
                  '#2e7d32'
                );
                
                widget.onBack();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.green700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Reclamar y Volver', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ] else ...[
            _buildWordleKeyboard(),
          ],
        ],
      ),
    );
  }
}
