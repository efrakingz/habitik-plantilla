import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';

import 'dart:async';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final FamilyService _familyService = FamilyService();
  int _step = 0;
  String? _rol;
  int? _personas;
  String? _qrToken;
  bool _creatingFamily = false;
  bool _scanning = false;
  final Map<String, String> _encuesta = {};
  final TextEditingController _codeCtrl = TextEditingController(text: 'HAB-');
  Timer? _qrTimer;
  int _qrTimeLeft = 600;

  @override
  void initState() {
    super.initState();
    // Lock navigation so refreshProfile() mid-flow doesn't kick us to Dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().setOnboardingActive(true);
    });
    // Prevent the user from deleting the 'HAB-' prefix in the code field and force uppercase
    _codeCtrl.addListener(() {
      final currentText = _codeCtrl.text;
      if (!currentText.toUpperCase().startsWith('HAB-')) {
        _codeCtrl.value = _codeCtrl.value.copyWith(
          text: 'HAB-',
          selection: const TextSelection.collapsed(offset: 4),
        );
      } else {
        final upperText = currentText.toUpperCase();
        if (currentText != upperText) {
          final selectionIndex = _codeCtrl.selection.baseOffset;
          _codeCtrl.value = _codeCtrl.value.copyWith(
            text: upperText,
            selection: TextSelection.collapsed(offset: selectionIndex),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _qrTimer?.cancel();
    super.dispose();
  }

  String get _fmtQrTime {
    final m = (_qrTimeLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_qrTimeLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String? _familyCode; // hub-XXXXXXXX for visible display

  Future<void> _nextStep() async {
    // Step 1 jefe: create family then immediately generate QR token
    if (_step == 1 && _rol == 'jefe') {
      setState(() => _creatingFamily = true);
      try {
        final profile = context.read<AuthProvider>().profile;
        if (profile != null) {
          await _familyService.createFamily(profile.id, _personas ?? 1);
          if (!mounted) return;
          await context.read<AuthProvider>().refreshProfile();
          if (!mounted) return;
          // Generate QR right away so it's ready when we show step 2
          final updatedProfile = context.read<AuthProvider>().profile;
          if (updatedProfile?.familyId != null) {
            final qrData = await _familyService.getOrGenerateActiveQRToken(updatedProfile!.familyId!);
            _qrToken = qrData['token'] as String?;
            _qrTimeLeft = qrData['timeLeft'] as int? ?? 600;
            _familyCode = _qrToken;

            _qrTimer?.cancel();
            _qrTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
              if (_qrTimeLeft > 0) {
                if (mounted) {
                  setState(() => _qrTimeLeft--);
                }
              } else {
                timer.cancel();
                if (mounted) {
                  setState(() {
                    _qrToken = null;
                  });
                }
              }
            });
          }
        }
      } catch (_) {}
      if (!mounted) return;
      setState(() => _creatingFamily = false);
    }

    setState(() => _step++);
  }

  void _onQRScan(String data) async {
    setState(() => _scanning = false);
    try {
      // First try to parse as JSON if it's the old format, otherwise treat as direct token
      String tokenToValidate = data;
      try {
        final json = jsonDecode(data);
        if (json.containsKey('token')) {
          tokenToValidate = json['token'];
        }
      } catch (_) {}

      final familyId = await _familyService.validateFamilyCode(tokenToValidate);
      if (familyId != null) {
        if (!mounted) return;
        final profile = context.read<AuthProvider>().profile;
        if (profile != null) {
          await _familyService.linkMember(profile.id, familyId);
          if (!mounted) return;
          await context.read<AuthProvider>().refreshProfile();
          
          // Notify the Jefes
          try {
            final jefes = await _familyService.getFamilyMembers(familyId);
            for (var jefe in jefes.where((m) => m.rol.toLowerCase().contains('jefe'))) {
              NotificationProvider.writeNotificationForUser(
                jefe.id,
                NotificationItem(
                  id: '${DateTime.now().millisecondsSinceEpoch}_join',
                  title: '¡Nuevo miembro!',
                  desc: '${profile.nombre.split(' ')[0]} se ha unido al hogar.',
                  time: DateTime.now().toIso8601String(),
                  iconCode: 'person_add',
                  colorHex: '#4CAF50',
                ),
              );
            }
          } catch (e) {
            debugPrint('Failed to notify jefes: $e');
          }

          if (mounted) setState(() => _step = 2);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR invalido o expirado'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al leer QR'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppTheme.green700,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.eco, color: AppTheme.green700, size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text('Habitik', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Progreso del registro', style: TextStyle(color: AppTheme.green200, fontSize: 12)),
                        Builder(builder: (ctx) {
                          final total = _rol == 'jefe' ? 6 : 5;
                          final pct = ((_step.clamp(0, total - 1) + 1) / total * 100).round();
                          return Text('$pct%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700));
                        }),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          width: double.infinity,
                          decoration: BoxDecoration(color: AppTheme.green600, borderRadius: BorderRadius.circular(4)),
                        ),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final total = _rol == 'jefe' ? 6 : 5;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOut,
                              height: 8,
                              width: constraints.maxWidth * ((_step.clamp(0, total - 1) + 1) / total),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                gradient: const LinearGradient(
                                  colors: [AppTheme.amber400, Color(0xFFFFB300)],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Builder(builder: (ctx) {
                      final total = _rol == 'jefe' ? 6 : 5;
                      final rem = total - (_step.clamp(0, total - 1) + 1);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Paso ${_step.clamp(0, total - 1) + 1} de $total', style: const TextStyle(color: AppTheme.green200, fontSize: 11)),
                          Text('$rem paso${rem != 1 ? 's' : ''} restante${rem != 1 ? 's' : ''}', style: const TextStyle(color: AppTheme.green200, fontSize: 11)),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildStepContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0: return _buildRoleStep();
      // Step 1: jefe=personas / miembro=scan QR
      case 1: return _rol == 'jefe' ? _buildPersonasStep() : _buildQRScanStep();
      // Step 2: both = habit survey
      case 2: return _buildHabitosEncuestaStep();
      // Step 3: jefe=infraestructura / miembro=retos recomendados
      case 3: return _rol == 'jefe' ? _buildInfraestructuraStep() : _buildRetosRecomendadosStep();
      // Step 4: jefe=retos recomendados / miembro=finish
      case 4: return _rol == 'jefe' ? _buildRetosRecomendadosStep() : _buildFinishStep();
      // Step 5: jefe=finish
      case 5: return _buildFinishStep();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildRoleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Constitucion del Hogar', style: TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Cual es tu rol en la familia?', style: TextStyle(color: AppTheme.green500, fontSize: 14)),
        const SizedBox(height: 24),
        _roleCard('jefe', Icons.shield_outlined, 'Jefe de Familia', 'Acceso completo: metas, presupuesto, tareas y auditoria de boletas.'),
        const SizedBox(height: 12),
        _roleCard('miembro', Icons.people_outline, 'Miembro', 'Retos, gamificacion y seguimiento personal de habitos.'),
        const SizedBox(height: 32),
        _continueButton(_rol != null),
      ],
    );
  }

  Widget _roleCard(String role, IconData icon, String title, String desc) {
    final selected = _rol == role;
    return GestureDetector(
      onTap: () => setState(() => _rol = role),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? AppTheme.green600 : AppTheme.green100, width: 2),
          borderRadius: BorderRadius.circular(16),
          color: selected ? AppTheme.green50 : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: selected ? AppTheme.green600 : AppTheme.green100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: selected ? Colors.white : AppTheme.green500, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(desc, style: const TextStyle(color: AppTheme.textLight, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonasStep() {
    final emojis = ['🧍', '👫', '👨‍👩‍👦', '👨‍👩‍👧‍👦', '🏠'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tu Hogar', style: TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Cuantas personas viven aqui?', style: TextStyle(color: AppTheme.green500, fontSize: 14)),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: [1, 2, 3, 4, 5].map((n) {
            final selected = _personas == n;
            return GestureDetector(
              onTap: () => setState(() => _personas = n),
              child: Container(
                width: (MediaQuery.of(context).size.width - 70) / 3,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: selected ? AppTheme.green700 : AppTheme.green200, width: 2),
                  borderRadius: BorderRadius.circular(14),
                  color: selected ? AppTheme.green700 : AppTheme.green50,
                ),
                child: Column(
                  children: [
                    Text(emojis[n - 1], style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 2),
                    Text(n == 5 ? '5 o mas' : '$n persona${n > 1 ? "s" : ""}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppTheme.textDark)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        _continueButton(_personas != null, loading: _creatingFamily, text: _creatingFamily ? 'Creando hogar...' : 'Continuar'),
      ],
    );
  }

  Future<void> _iniciarScan() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      if (!mounted) return;
      setState(() => _scanning = true);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se requiere permiso de cámara para escanear'), backgroundColor: Colors.orange),
      );
    }
  }

  Widget _buildQRScanStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Unirse al Hogar', style: TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Escanea el QR o ingresa el código del jefe de familia', style: TextStyle(color: AppTheme.green500, fontSize: 14)),
        const SizedBox(height: 20),
        if (_scanning)
          SizedBox(
            height: 280,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: MobileScanner(onDetect: (capture) {
                final barcode = capture.barcodes.first;
                if (barcode.rawValue != null) _onQRScan(barcode.rawValue!);
              }),
            ),
          )
        else
          GestureDetector(
            onTap: _iniciarScan,
            child: Container(
              width: double.infinity, height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.green300),
                borderRadius: BorderRadius.circular(16),
                color: AppTheme.green50,
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner, color: AppTheme.green400, size: 48),
                  SizedBox(height: 8),
                  Text('Toca para abrir la cámara', style: TextStyle(color: AppTheme.green500, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.amber400.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.amber400.withAlpha(77)),
          ),
          child: const Row(
            children: [
              Icon(Icons.timer_outlined, color: AppTheme.amber400, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('El código/QR del jefe de familia expira en 10 minutos', style: TextStyle(color: AppTheme.amber400, fontSize: 12, fontWeight: FontWeight.w600))),
            ],
          ),
        ),
        if (!_scanning) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(child: Divider(color: AppTheme.green200)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('o ingresa manualmente', style: TextStyle(color: AppTheme.textLight, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const Expanded(child: Divider(color: AppTheme.green200)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeCtrl,
                  onSubmitted: (val) {
                    if (val.length >= 8) {
                      _onQRScan(val);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'HAB-XXXXXXXX',
                    hintStyle: const TextStyle(color: AppTheme.textLight),
                    prefixIcon: const Icon(Icons.keyboard, color: AppTheme.green400),
                    filled: true,
                    fillColor: AppTheme.green50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.green200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.green200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.green500, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.green600,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  onPressed: () {
                    if (_codeCtrl.text.length >= 8) {
                      _onQRScan(_codeCtrl.text);
                    }
                  },
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildHabitosEncuestaStep() {
    final preguntas = <Map<String, Object>>[
      {
        'key': 'ducha',
        'cat': '💧 Agua',
        'label': '¿Cuánto tiempo te demoras en duchar aproximadamente?',
        'ops': <String>['Menos de 5 min', '5 a 10 min', '10 a 15 min', 'Más de 15 min']
      },
      {
        'key': 'hervidor',
        'cat': '⚡ Energía',
        'label': '¿Cuántas veces al día usas el hervidor eléctrico?',
        'ops': <String>['No lo utilizo', '1 a 2 veces al día', '3 a 5 veces al día', 'Más de 5 veces al día']
      },
      {
        'key': 'luces',
        'cat': '⚡ Energía',
        'label': '¿Cuántas horas al día dejas luces encendidas en habitaciones vacías?',
        'ops': <String>['Menos de 1 hora', '1 a 3 horas', '3 a 6 horas', 'Más de 6 horas']
      },
      {
        'key': 'vampiros',
        'cat': '⚡ Energía',
        'label': '¿Dejas cargadores y electrodomésticos enchufados sin usarlos?',
        'ops': <String>['Nunca', 'A veces', 'Siempre']
      },
      {
        'key': 'lavadora',
        'cat': '💧 Agua',
        'label': '¿Con qué frecuencia utilizas la lavadora a la semana?',
        'ops': <String>['1 vez o menos', '2 a 3 veces', '4 veces o más', 'No la utilizo']
      },
      {
        'key': 'llave_cepillo',
        'cat': '💧 Agua',
        'label': '¿Cierras la llave del agua mientras te cepillas los dientes o te afeitas?',
        'ops': <String>['Siempre', 'A veces', 'Nunca']
      },
    ];

    final allAnswered = preguntas.every((q) => _encuesta.containsKey(q['key'] as String));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tus Hábitos Diarios',
          style: TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Responde honestamente para calcular tu impacto de consumo estimado.',
          style: TextStyle(color: AppTheme.green500, fontSize: 14),
        ),
        const SizedBox(height: 20),
        ...preguntas.map((q) {
          final cat = q['cat'] as String;
          final label = q['label'] as String;
          final key = q['key'] as String;
          final ops = q['ops'] as List<String>;
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.green100, borderRadius: BorderRadius.circular(8)),
                  child: Text(cat, style: const TextStyle(color: AppTheme.textDark, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: ops.map((op) {
                    final selected = _encuesta[key] == op;
                    return GestureDetector(
                      onTap: () => setState(() => _encuesta[key] = op),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.green700 : AppTheme.green50,
                          border: Border.all(color: selected ? AppTheme.green700 : AppTheme.green200, width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(op, style: TextStyle(
                          color: selected ? Colors.white : AppTheme.textDark,
                          fontSize: 12, fontWeight: FontWeight.w600,
                        )),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        _continueButton(allAnswered),
      ],
    );
  }

  Widget _buildInfraestructuraStep() {
    final preguntas = <Map<String, Object>>[
      {
        'key': 'tipoVivienda',
        'cat': '🏠 Vivienda',
        'label': '¿Qué tipo de vivienda tiene tu familia?',
        'ops': <String>['Departamento', 'Casa de 1 piso', 'Casa de 2 o más pisos', 'Otro']
      },
      {
        'key': 'climatizacion',
        'cat': '🌡️ Calefacción',
        'label': '¿Qué sistema de calefacción principal utilizan en invierno?',
        'ops': <String>['Calefacción eléctrica', 'Estufa a gas licuado (balón)', 'Estufa a parafina (kerosene)', 'No climatizamos (Solo abrigo y ventilación)']
      },
      {
        'key': 'electrodomesticos',
        'cat': '⚡ Consumos',
        'label': '¿Cuáles de estos electrodomésticos de alto consumo se usan frecuentemente en casa?',
        'ops': <String>['Secadora de ropa', 'Aire acondicionado', 'Lavavajillas', 'Solo lo básico']
      },
      {
        'key': 'gastoLuz',
        'cat': '💰 Electricidad',
        'label': '¿Cuánto pagan aproximadamente en tu boleta mensual de luz?',
        'ops': <String>['Menos de \$35.000 CLP', 'Entre \$35.000 y \$75.000 CLP', 'Entre \$75.000 y \$120.000 CLP', 'Más de \$120.000 CLP']
      },
      {
        'key': 'gastoAgua',
        'cat': '💰 Agua',
        'label': '¿Cuánto pagan aproximadamente en tu boleta mensual de agua?',
        'ops': <String>['Menos de \$20.000 CLP', 'Entre \$20.000 y \$35.000 CLP', 'Entre \$35.000 y \$60.000 CLP', 'Más de \$60.000 CLP']
      },
      {
        'key': 'frecuenciaBoleta',
        'cat': '📊 Gestión',
        'label': '¿Con qué frecuencia revisan o pagan estas boletas?',
        'ops': <String>['Mensual', 'Bimestral', 'Cuando se vence / Al acordarse']
      },
    ];

    final allAnswered = preguntas.every((q) => _encuesta.containsKey(q['key'] as String));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Infraestructura y Gastos del Hogar',
          style: TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Información exclusiva del Jefe de Familia para configurar metas de consumo.',
          style: TextStyle(color: AppTheme.green500, fontSize: 14),
        ),
        const SizedBox(height: 20),
        ...preguntas.map((q) {
          final cat = q['cat'] as String;
          final label = q['label'] as String;
          final key = q['key'] as String;
          final ops = q['ops'] as List<String>;
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.green100, borderRadius: BorderRadius.circular(8)),
                  child: Text(cat, style: const TextStyle(color: AppTheme.textDark, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: ops.map((op) {
                    final selected = _encuesta[key] == op;
                    return GestureDetector(
                      onTap: () => setState(() => _encuesta[key] = op),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.green700 : AppTheme.green50,
                          border: Border.all(color: selected ? AppTheme.green700 : AppTheme.green200, width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(op, style: TextStyle(
                          color: selected ? Colors.white : AppTheme.textDark,
                          fontSize: 12, fontWeight: FontWeight.w600,
                        )),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        _continueButton(allAnswered),
      ],
    );
  }

  Widget _buildFinishStep() {
    final profile = context.read<AuthProvider>().profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _rol == 'jefe' ? '¡Hogar listo!' : '¡Ya estás dentro!',
          style: const TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          _rol == 'jefe' ? 'Comparte el QR con tu familia para que se unan.' : 'Ya formas parte del hogar. ¡A ganar XP!',
          style: const TextStyle(color: AppTheme.green500, fontSize: 14),
        ),
        const SizedBox(height: 20),
        // ✅ Check icon
        Center(
          child: Column(
            children: [
              Container(
                width: 72, height: 72,
                decoration: const BoxDecoration(color: AppTheme.green100, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, color: AppTheme.green600, size: 40),
              ),
              const SizedBox(height: 8),
              Text(
                _rol == 'jefe' ? 'Hogar creado exitosamente' : 'Hogar vinculado',
                style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        // QR only for jefe
        if (_rol == 'jefe') ...[
          const SizedBox(height: 20),
          if (_qrToken != null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppTheme.green600, width: 2),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12)],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: jsonEncode({'token': _qrToken, 'family_id': profile?.familyId ?? ''}),
                      version: QrVersions.auto,
                      size: 180,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.green700),
                      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppTheme.green700),
                    ),
                    const SizedBox(height: 8),
                    if (_familyCode != null)
                      Text(_familyCode!, style: const TextStyle(color: AppTheme.textDark, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    const SizedBox(height: 2),
                    const Text('Muestra este QR o comparte el código', style: TextStyle(color: AppTheme.textLight, fontSize: 11)),
                  ],
                ),
              ),
            )
          else
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppTheme.green500))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.amber400.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.amber400.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: AppTheme.amber400, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _qrToken != null
                        ? 'Este QR expira en $_fmtQrTime. Puedes generar uno nuevo desde tu perfil.'
                        : 'El código ha expirado. Puedes generar uno nuevo desde tu perfil.',
                    style: const TextStyle(color: AppTheme.amber400, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: () {
              context.read<AuthProvider>().setOnboardingActive(false);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.green700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Ir al Dashboard', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  /// Analyses _encuesta and returns 3 recommended reto IDs with their metadata.
  List<Map<String, String>> _getRetosRecomendados() {
    final recomendados = <Map<String, String>>[];

    // Ducha larga → Speedrun de la Ducha
    final ducha = _encuesta['ducha'] ?? '';
    if (ducha == '10 a 15 min' || ducha == 'Más de 15 min') {
      recomendados.add({'emoji': '🚿', 'titulo': 'Speedrun de la Ducha', 'desc': 'Ducharte en menos de 10 min', 'xp': '50', 'id': 'ducha'});
    }

    // Luces innecesarias o llave abierta → Inspección del Día
    final luces = _encuesta['luces'] ?? '';
    final llave = _encuesta['llave_cepillo'] ?? '';
    if (luces == '3 a 6 horas' || luces == 'Más de 6 horas' || llave == 'A veces' || llave == 'Nunca') {
      recomendados.add({'emoji': '🔍', 'titulo': 'Inspección del Día', 'desc': 'Sube una foto de la misión de hoy', 'xp': '100', 'id': 'inspeccion'});
    }

    // Hervidor constante → Trivia Infinita
    final hervidor = _encuesta['hervidor'] ?? '';
    if (hervidor == '3 a 5 veces al día' || hervidor == 'Más de 5 veces al día') {
      recomendados.add({'emoji': '🧠', 'titulo': 'Trivia Infinita', 'desc': '3 vidas · preguntas de ecología', 'xp': '150', 'id': 'trivia'});
    }

    // Vampiros de energía → Eco-Puzzle Temático
    final vampiros = _encuesta['vampiros'] ?? '';
    if (vampiros == 'Siempre' || vampiros == 'A veces') {
      recomendados.add({'emoji': '🎯', 'titulo': 'Eco-Puzzle', 'desc': 'Clasifica residuos en 60 segundos', 'xp': '120', 'id': 'puzzle'});
    }

    // Defaults in case we need to pad
    final defaults = [
      {'emoji': '🚿', 'titulo': 'Speedrun de la Ducha', 'desc': 'Ducharte en menos de 10 min', 'xp': '50', 'id': 'ducha'},
      {'emoji': '🧠', 'titulo': 'Trivia Infinita', 'desc': '3 vidas · preguntas de ecología', 'xp': '150', 'id': 'trivia'},
      {'emoji': '🎯', 'titulo': 'Eco-Puzzle', 'desc': 'Clasifica residuos en 60 segundos', 'xp': '120', 'id': 'puzzle'},
      {'emoji': '🔍', 'titulo': 'Inspección del Día', 'desc': 'Sube una foto de la misión de hoy', 'xp': '100', 'id': 'inspeccion'},
    ];
    for (final d in defaults) {
      if (recomendados.length >= 3) break;
      if (!recomendados.any((r) => r['titulo'] == d['titulo'])) recomendados.add(d);
    }

    return recomendados.take(3).toList();
  }

  Widget _buildRetosRecomendadosStep() {
    final retos = _getRetosRecomendados();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🎯 Tus Retos Recomendados',
          style: TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Basado en tus hábitos, estos retos son ideales para ti',
          style: TextStyle(color: AppTheme.green500, fontSize: 14)),
        const SizedBox(height: 20),
        ...retos.map((r) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF1F8E9), Color(0xFFE8F5E9)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.green200),
          ),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)],
                ),
                child: Center(child: Text(r['emoji']!, style: const TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r['titulo']!, style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(r['desc']!, style: const TextStyle(color: AppTheme.textLight, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.green700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('+${r['xp']} XP',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
              ),
            ],
          ),
        )),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.amber400.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.amber400.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Text('💡', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Completa 2 retos al día para desbloquear el Bonus de Constancia (+30 XP · +15 🪙)',
                  style: TextStyle(color: Color(0xFF795548), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _continueButton(true, text: '¡Empieza ya! →'),
      ],
    );
  }

  Widget _continueButton(bool enabled, {bool loading = false, String text = 'Continuar'}) {
    return SizedBox(
      width: double.infinity, height: 50,
      child: ElevatedButton(
        onPressed: enabled && !loading ? _nextStep : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled && !loading ? AppTheme.green700 : AppTheme.green100,
          foregroundColor: enabled && !loading ? Colors.white : AppTheme.green300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
      ),
    );
  }

}
