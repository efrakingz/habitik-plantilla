import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../providers/task_provider.dart';
import 'shared_ui.dart';

class EvidenceChallenge extends StatefulWidget {
  final VoidCallback onBack;
  final SubmitChallengeFunc onSubmit;
  final String active;

  const EvidenceChallenge({super.key, required this.onBack, required this.onSubmit, required this.active});

  @override
  State<EvidenceChallenge> createState() => _EvidenceChallengeState();
}

class _EvidenceChallengeState extends State<EvidenceChallenge> {
  List<String> _evidenceImages = [];
  bool _isSubmitting = false;

  Future<void> _pickEvidenceImage(int maxImages) async {
    final picker = ImagePicker();
    if (maxImages > 1) {
      final List<XFile> images = await picker.pickMultiImage(maxWidth: 600);
      if (images.isNotEmpty) {
        setState(() {
          _evidenceImages.addAll(images.map((e) => e.path));
          if (_evidenceImages.length > maxImages) {
            _evidenceImages = _evidenceImages.sublist(0, maxImages);
          }
        });
      }
    } else {
      XFile? image;
      try {
        image = await picker.pickImage(source: ImageSource.camera, maxWidth: 600);
      } catch (e) {
        image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 600);
      }
      
      if (image != null) {
        setState(() {
          _evidenceImages = [image!.path];
        });
      }
    }
  }

  @override
  void dispose() {
    _evidenceImages.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final misiones = <Map<String, dynamic>>[
      {
        'titulo': 'Consola en Reposo',
        'instruccion': 'Inspecciona tu consola de videojuegos (PlayStation/Xbox/Switch) o PC. Asegúrate de que esté apagada por completo, no en modo de suspensión o reposo. Sube una foto de la consola apagada sin su luz LED activa.',
        'emoji': '🎮',
      },
      {
        'titulo': 'Cargador Desconectado',
        'instruccion': 'Desenchufa de la pared el cargador de tu celular, tablet o notebook al terminar de usarlo para evitar el consumo fantasma. Toma una foto del cargador desenchufado.',
        'emoji': '🔌',
      },
      {
        'titulo': 'Llave al Lavarse',
        'instruccion': 'Evita desperdiciar agua. Asegúrate de cerrar la llave del lavamanos mientras te enjabonas las manos o te cepillas los dientes. Toma una foto de la llave cerrada en el baño.',
        'emoji': '🚰',
      },
      {
        'titulo': 'Refrigerador Cerrado',
        'instruccion': 'Revisa que la puerta del refrigerador esté completamente cerrada y que el sello magnético encaje de forma hermética para que no se escape el frío. Toma una foto de la puerta cerrada.',
        'emoji': '❄️',
      },
      {
        'titulo': 'Cortina y Luz Natural',
        'instruccion': 'Aprovecha la luz del sol en tu habitación. Abre por completo las cortinas o persianas y mantén apagada la luz artificial de tu pieza durante el día. Toma una foto de la ventana iluminada y la luz apagada.',
        'emoji': '☀️',
      },
      {
        'titulo': 'Interruptor de Alargador',
        'instruccion': 'Apaga el botón rojo/interruptor del alargador o zapatilla eléctrica para cortar el suministro de todos los cargadores y evitar el consumo vampiro. Sube foto del interruptor apagado.',
        'emoji': '🔌',
      },
      {
        'titulo': 'Hervidor con Medidor',
        'instruccion': 'Al usar el hervidor de agua, llénalo midiendo la cantidad exacta de tazas que vas a consumir, en lugar de calentarlo lleno. Toma una foto del medidor del hervidor con el nivel exacto.',
        'emoji': '☕',
      },
      {
        'titulo': 'Cajas Desarmadas',
        'instruccion': 'Antes de llevar cartón o cajas de Tetra Pak al reciclaje, desármalas, aplástalas y dobla sus esquinas para optimizar el espacio en el basurero. Toma una foto de la caja completamente plana.',
        'emoji': '📦',
      },
      {
        'titulo': 'Botellas Compactadas',
        'instruccion': 'Para reciclar botellas PET, quítales la tapa, aplástalas con cuidado para reducir su volumen y luego colócalas en el contenedor. Sube una foto de la botella compactada y lista.',
        'emoji': '🧴',
      },
      {
        'titulo': 'Luz en Habitación Vacía',
        'instruccion': 'Inspecciona las zonas comunes e individuales de tu hogar. Asegúrate de apagar los focos de cualquier habitación que se encuentre desocupada. Sube foto del interruptor apagado o de la pieza desocupada.',
        'emoji': '💡',
      },
      {
        'titulo': 'Riego con Regadera',
        'instruccion': 'Riega tus plantas o maceteros utilizando un vaso, botella de agua reutilizada o regadera en la tarde/noche para evitar que el sol evapore el agua. Sube foto regando responsablemente.',
        'emoji': '🌱',
      },
      {
        'titulo': 'Útiles en Orden',
        'instruccion': 'Al terminar de estudiar o hacer tareas, ordena tus cuadernos y estuche, y asegúrate de no dejar lámparas de escritorio encendidas ni pantallas de tablet en stand-by. Sube una foto de tu mesa ordenada.',
        'emoji': '📚',
      },
      {
        'titulo': 'Uso Eficiente del Lavaplatos',
        'instruccion': 'Reúne la loza sucia y espera a tener una cantidad suficiente para realizar un lavado eficiente, evitando usar chorros continuos de agua por cada plato suelto. Sube una foto de la loza organizada lista para lavar.',
        'emoji': '🍽️',
      },
      {
        'titulo': 'Ventilación Natural',
        'instruccion': 'Abre la ventana de tu habitación durante 10 a 15 minutos en la mañana para ventilar y renovar el aire de forma natural sin necesidad de ventiladores o climatizadores. Toma una foto de la ventana abierta.',
        'emoji': '🪟',
      },
      {
        'titulo': 'Secado al Sol',
        'instruccion': 'Aprovecha el viento y el sol natural para secar la ropa o los paños de cocina tendidos en el colgador, evitando encender la secadora eléctrica. Sube foto de la ropa colgada al aire libre.',
        'emoji': '🧺',
      },
      {
        'titulo': 'Bolsa Reutilizable',
        'instruccion': 'Deja una bolsa de tela reutilizable doblada y visible cerca de la puerta principal o dentro de tu mochila para no olvidar llevarla en la próxima compra. Toma una foto de la bolsa lista.',
        'emoji': '🛍️',
      },
    ];

    final now = DateTime.now();
    final idx = (now.year * 365 + now.month * 31 + now.day) % misiones.length;
    final mision = misiones[idx];

    final emoji = mision['emoji'] as String;
    final titulo = 'Inspección: ${mision['titulo']}';
    final instruccion = mision['instruccion'] as String;
    const xp = 100;
    const monedas = 15;
    const maxImages = 1;

    return ChallengeShell(
      color: const Color(0xFFF57C00),
      title: '$emoji $titulo',
      onClose: () {
        setState(() => _evidenceImages.clear());
        widget.onBack();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0), 
              borderRadius: BorderRadius.circular(14), 
              border: Border.all(color: const Color(0xFFFFB74D)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Misión de Inspección Diaria', 
                  style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFE65100), fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  instruccion, 
                  style: const TextStyle(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          if (_evidenceImages.isNotEmpty) ...[
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _evidenceImages.map((path) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(path), width: 150, height: 150, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: 4, top: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _evidenceImages.remove(path)),
                      child: Container(
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), 
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              )).toList(),
            ),
          ] else ...[
            GestureDetector(
              onTap: () => _pickEvidenceImage(maxImages),
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFFB74D), style: BorderStyle.solid), 
                  borderRadius: BorderRadius.circular(14), 
                  color: const Color(0xFFFFF8E1),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, 
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, color: Color(0xFFF57C00), size: 36),
                      SizedBox(height: 6),
                      Text(
                        'Toca para subir foto de evidencia', 
                        style: TextStyle(color: Color(0xFFE65100), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                RewardStat(value: '+$xp XP', label: 'Nivel', color: AppTheme.textDark),
                const SizedBox(width: 20),
                RewardStat(value: '+$monedas 🪙', label: 'Canjes', color: AppTheme.amber400),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (context.watch<TaskProvider>().completedRetos.contains(widget.active))
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.amber400.withValues(alpha: 0.2), 
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty, color: AppTheme.amber400, size: 16),
                  SizedBox(width: 8),
                  Text('Enviado a revisión', style: TextStyle(color: AppTheme.amber400, fontWeight: FontWeight.w800)),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: (_evidenceImages.length == maxImages && !_isSubmitting) ? () async {
                  setState(() => _isSubmitting = true);
                  await widget.onSubmit(
                    widget.active, 
                    titulo, 
                    xp, 
                    monedas, 
                    _evidenceImages, 
                    true, 
                    '#f57c00'
                  );
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evidencia enviada al Jefe de Familia')));
                  if (mounted) {
                    setState(() {
                      _evidenceImages.clear();
                      _isSubmitting = false;
                    });
                  }
                  widget.onBack();
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF57C00), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Enviar Evidencia', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
        ],
      ),
    );
  }
}
