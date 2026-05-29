import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../dashboard/dashboard_screen.dart';
import 'onboarding_controller.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final controller = OnboardingController();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<AuthProvider>().setOnboardingActive(true);
        });
        return controller;
      },
      child: const _OnboardingScreenContent(),
    );
  }
}

class _OnboardingScreenContent extends StatelessWidget {
  const _OnboardingScreenContent();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OnboardingController>();

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
                          final total = controller.rol == 'jefe' ? 6 : 5;
                          final pct = ((controller.step.clamp(0, total - 1) + 1) / total * 100).round();
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
                            final total = controller.rol == 'jefe' ? 6 : 5;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOut,
                              height: 8,
                              width: constraints.maxWidth * ((controller.step.clamp(0, total - 1) + 1) / total),
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
                      final total = controller.rol == 'jefe' ? 6 : 5;
                      final rem = total - (controller.step.clamp(0, total - 1) + 1);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Paso ${controller.step.clamp(0, total - 1) + 1} de $total', style: const TextStyle(color: AppTheme.green200, fontSize: 11)),
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
                    child: _buildStepContent(context, controller),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, OnboardingController controller) {
    switch (controller.step) {
      case 0: return _buildRoleStep(context, controller);
      case 1: return controller.rol == 'jefe' ? _buildPersonasStep(context, controller) : _buildQRScanStep(context, controller);
      case 2: return _buildHabitosEncuestaStep(context, controller);
      case 3: return controller.rol == 'jefe' ? _buildInfraestructuraStep(context, controller) : _buildRetosRecomendadosStep(context, controller);
      case 4: return controller.rol == 'jefe' ? _buildRetosRecomendadosStep(context, controller) : _buildFinishStep(context, controller);
      case 5: return _buildFinishStep(context, controller);
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildRoleStep(BuildContext context, OnboardingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Constitucion del Hogar', style: TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Cual es tu rol en la familia?', style: TextStyle(color: AppTheme.green500, fontSize: 14)),
        const SizedBox(height: 24),
        _roleCard(controller, 'jefe', Icons.shield_outlined, 'Jefe de Familia', 'Acceso completo: metas, presupuesto, tareas y auditoria de boletas.'),
        const SizedBox(height: 12),
        _roleCard(controller, 'miembro', Icons.people_outline, 'Miembro', 'Retos, gamificacion y seguimiento personal de habitos.'),
        const SizedBox(height: 32),
        _continueButton(context, controller, enabled: controller.rol != null),
      ],
    );
  }

  Widget _roleCard(OnboardingController controller, String role, IconData icon, String title, String desc) {
    final selected = controller.rol == role;
    return GestureDetector(
      onTap: () => controller.setRol(role),
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

  Widget _buildPersonasStep(BuildContext context, OnboardingController controller) {
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
            final selected = controller.personas == n;
            return GestureDetector(
              onTap: () => controller.setPersonas(n),
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
        _continueButton(context, controller, enabled: controller.personas != null, loading: controller.creatingFamily, text: controller.creatingFamily ? 'Creando hogar...' : 'Continuar'),
      ],
    );
  }

  Widget _buildQRScanStep(BuildContext context, OnboardingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Unirse al Hogar', style: TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Escanea el QR o ingresa el código del jefe de familia', style: TextStyle(color: AppTheme.green500, fontSize: 14)),
        const SizedBox(height: 20),
        if (controller.scanning)
          SizedBox(
            height: 280,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: MobileScanner(onDetect: (capture) {
                final barcode = capture.barcodes.first;
                if (barcode.rawValue != null) controller.onQRScan(context, barcode.rawValue!);
              }),
            ),
          )
        else
          GestureDetector(
            onTap: () => controller.iniciarScan(context),
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
        if (!controller.scanning) ...[
          const SizedBox(height: 20),
          const Row(
            children: [
              Expanded(child: Divider(color: AppTheme.green200)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('o ingresa manualmente', style: TextStyle(color: AppTheme.textLight, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              Expanded(child: Divider(color: AppTheme.green200)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.codeCtrl,
                  onSubmitted: (val) {
                    if (val.length >= 8) {
                      controller.onQRScan(context, val);
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
                    if (controller.codeCtrl.text.length >= 8) {
                      controller.onQRScan(context, controller.codeCtrl.text);
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

  Widget _buildHabitosEncuestaStep(BuildContext context, OnboardingController controller) {
    final preguntas = <Map<String, Object>>[
      {
        'key': 'ducha',
        'cat': '💧 Agua',
        'label': '¿Cuánto tiempo te demoras en duchar aproximadamente?',
        'ops': <String>['Menos de 5 min', '5 a 10 min', '10 a 15 min', 'Más de 15 min']
      },
      {
        'key': 'reciclaje',
        'cat': '♻️ Reciclaje',
        'label': '¿Separan residuos para reciclar en tu hogar?',
        'ops': <String>['No reciclamos', 'Separamos lo básico', 'Separamos todo']
      },
      {
        'key': 'urgencia',
        'cat': '🚨 Urgencia',
        'label': '¿Cuál consideras que es la problemática más urgente a resolver?',
        'ops': <String>['Gasto de Luz', 'Gasto de Agua', 'Falta de Reciclaje']
      },
      {
        'key': 'horario',
        'cat': '⏰ Notificaciones',
        'label': '¿En qué horario está la casa llena para recibir alertas?',
        'ops': <String>['Mañana: 07:00 - 12:00', 'Tarde: 12:00 - 18:00', 'Noche: 18:00 - 23:00']
      },
    ];

    final allAnswered = preguntas.every((q) => controller.encuesta.containsKey(q['key'] as String));

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
                    final selected = controller.encuesta[key] == op;
                    return GestureDetector(
                      onTap: () => controller.setEncuesta(key, op),
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
        _continueButton(context, controller, enabled: allAnswered),
      ],
    );
  }

  Widget _buildInfraestructuraStep(BuildContext context, OnboardingController controller) {
    final preguntas = <Map<String, Object>>[
      {
        'key': 'ahorro',
        'cat': '💰 Ahorro',
        'label': '¿Cuánto dinero quieren ahorrar este mes?',
        'ops': <String>['Un 5% (Meta conservadora)', 'Un 10% (Meta recomendada)', 'Un 20% (Eco-Expertos)']
      },
    ];

    final allAnswered = preguntas.every((q) => controller.encuesta.containsKey(q['key'] as String));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meta de Ahorro Familiar',
          style: TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Información exclusiva del Jefe de Familia para configurar las metas y límites de gasto del mes.',
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
                    final selected = controller.encuesta[key] == op;
                    return GestureDetector(
                      onTap: () => controller.setEncuesta(key, op),
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
        _continueButton(context, controller, enabled: allAnswered),
      ],
    );
  }

  Widget _buildRetosRecomendadosStep(BuildContext context, OnboardingController controller) {
    final retos = controller.getRetosRecomendados();
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
        _continueButton(context, controller, enabled: true, text: '¡Empieza ya! →'),
      ],
    );
  }

  Widget _buildFinishStep(BuildContext context, OnboardingController controller) {
    final profile = context.read<AuthProvider>().profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          controller.rol == 'jefe' ? '¡Hogar listo!' : '¡Ya estás dentro!',
          style: const TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          controller.rol == 'jefe' ? 'Comparte el QR con tu familia para que se unan.' : 'Ya formas parte del hogar. ¡A ganar XP!',
          style: const TextStyle(color: AppTheme.green500, fontSize: 14),
        ),
        const SizedBox(height: 20),
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
                controller.rol == 'jefe' ? 'Hogar creado exitosamente' : 'Hogar vinculado',
                style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        if (controller.rol == 'jefe') ...[
          const SizedBox(height: 20),
          if (controller.qrToken != null)
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
                      data: jsonEncode({'token': controller.qrToken, 'family_id': profile?.familyId ?? ''}),
                      version: QrVersions.auto,
                      size: 180,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.green700),
                      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppTheme.green700),
                    ),
                    const SizedBox(height: 8),
                    if (controller.familyCode != null)
                      Text(controller.familyCode!, style: const TextStyle(color: AppTheme.textDark, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
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
                    controller.qrToken != null
                        ? 'Este QR expira en ${controller.fmtQrTime}. Puedes generar uno nuevo desde tu perfil.'
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

  Widget _continueButton(BuildContext context, OnboardingController controller, {required bool enabled, bool loading = false, String text = 'Continuar'}) {
    return SizedBox(
      width: double.infinity, height: 50,
      child: ElevatedButton(
        onPressed: enabled && !loading ? () => controller.nextStep(context) : null,
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
