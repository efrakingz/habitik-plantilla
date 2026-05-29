import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/achievement_service.dart';
import '../services/task_service.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import '../providers/auth_provider.dart';

class AchievementProvider with ChangeNotifier {
  final AchievementService _achievementService = AchievementService();
  final TaskService _taskService = TaskService();
  // Static catalog of all 40 achievements
  final List<AchievementItem> _catalog = [
    // ==========================================
    // LOGROS FÁCILES (13) - Onboarding e Inicios
    // ==========================================
    AchievementItem(
      key: 'primer_registro',
      nombre: '¡Hola Mundo Verde!',
      desc: 'Sube tu primera evidencia al feed.',
      emoji: '🌿',
      dificultad: 'fácil',
      xp: 100,
      monedas: 10,
    ),
    AchievementItem(
      key: 'primer_recibo',
      nombre: 'Cuentas Claras',
      desc: 'Registra tu primer recibo de servicio.',
      emoji: '📝',
      dificultad: 'fácil',
      xp: 120,
      monedas: 15,
    ),
    AchievementItem(
      key: 'unirse_familia',
      nombre: 'Miembro Oficial',
      desc: 'Únete a un grupo familiar o crea uno nuevo.',
      emoji: '🏠',
      dificultad: 'fácil',
      xp: 150,
      monedas: 20,
    ),
    AchievementItem(
      key: 'primer_reto',
      nombre: 'Retador Inicial',
      desc: 'Completa o sube tu primer eco-reto.',
      emoji: '🚿',
      dificultad: 'fácil',
      xp: 100,
      monedas: 10,
    ),
    AchievementItem(
      key: 'primer_canje',
      nombre: 'El Esfuerzo Vale',
      desc: 'Canjea tu primera recompensa de la tienda.',
      emoji: '🎁',
      dificultad: 'fácil',
      xp: 120,
      monedas: 15,
    ),
    AchievementItem(
      key: 'primer_like_dado',
      nombre: 'Eco Apoyo',
      desc: 'Dale me gusta a la evidencia de un familiar.',
      emoji: '❤️',
      dificultad: 'fácil',
      xp: 50,
      monedas: 5,
    ),
    AchievementItem(
      key: 'perfil_completo',
      nombre: 'Identidad Eco',
      desc: 'Personaliza tu nombre o foto de perfil.',
      emoji: '🖼️',
      dificultad: 'fácil',
      xp: 80,
      monedas: 10,
    ),
    AchievementItem(
      key: 'primer_wordle',
      nombre: 'Léxico Verde',
      desc: 'Resuelve tu primer Eco-Wordle del día.',
      emoji: '🔠',
      dificultad: 'fácil',
      xp: 100,
      monedas: 15,
    ),
    AchievementItem(
      key: 'primera_sopa',
      nombre: 'Ojo de Halcón',
      desc: 'Encuentra todas las palabras en tu primera Sopa de Letras.',
      emoji: '🔍',
      dificultad: 'fácil',
      xp: 100,
      monedas: 15,
    ),
    AchievementItem(
      key: 'primer_conector',
      nombre: 'Eco Nexo',
      desc: 'Completa tu primer nivel en el Eco-Conector.',
      emoji: '🔄',
      dificultad: 'fácil',
      xp: 100,
      monedas: 15,
    ),
    AchievementItem(
      key: 'primer_speedrun',
      nombre: 'Ducha Flash',
      desc: 'Inicia y completa un Speedrun de la Ducha.',
      emoji: '🏃‍♂️',
      dificultad: 'fácil',
      xp: 120,
      monedas: 10,
    ),
    AchievementItem(
      key: 'recibir_un_like',
      nombre: 'Popular en Casa',
      desc: 'Recibe tu primer me gusta en una evidencia aprobada.',
      emoji: '👍',
      dificultad: 'fácil',
      xp: 60,
      monedas: 5,
    ),
    AchievementItem(
      key: 'primera_inspeccion',
      nombre: 'Inspector Verde',
      desc: 'Sube una foto de evidencia para la Inspección del Día.',
      emoji: '📸',
      dificultad: 'fácil',
      xp: 110,
      monedas: 10,
    ),

    // ==========================================
    // LOGROS MEDIOS (14) - Consistencia y Juegos
    // ==========================================
    AchievementItem(
      key: 'eco_trivia',
      nombre: 'Cerebro Verde',
      desc: 'Trivia perfecta (150 XP) en la Trivia Infinita.',
      emoji: '🧠',
      dificultad: 'medio',
      xp: 300,
      monedas: 50,
    ),
    AchievementItem(
      key: 'eco_puzzle',
      nombre: 'Maestro del Reciclaje',
      desc: 'Puntuación perfecta (30/30) en el Eco-Puzzle.',
      emoji: '🎯',
      dificultad: 'medio',
      xp: 300,
      monedas: 50,
    ),
    AchievementItem(
      key: 'racha_constancia',
      nombre: 'Eco Constancia',
      desc: 'Reclama el Bonus de Constancia Diaria.',
      emoji: '⚡',
      dificultad: 'medio',
      xp: 250,
      monedas: 40,
    ),
    AchievementItem(
      key: 'ahorro_agua',
      nombre: 'Ahorro Fluyente',
      desc: 'Registra 3 recibos de agua históricos.',
      emoji: '💧',
      dificultad: 'medio',
      xp: 250,
      monedas: 40,
    ),
    AchievementItem(
      key: 'ahorro_luz',
      nombre: 'Energía Limpia',
      desc: 'Registra 3 recibos de luz históricos.',
      emoji: '💡',
      dificultad: 'medio',
      xp: 250,
      monedas: 40,
    ),
    AchievementItem(
      key: 'trivia_25',
      nombre: 'Sabio Verde',
      desc: 'Responde 25 preguntas correctas seguidas en Trivia.',
      emoji: '🧙‍♂️',
      dificultad: 'medio',
      xp: 250,
      monedas: 30,
    ),
    AchievementItem(
      key: 'trivia_50',
      nombre: 'Erudito de la Tierra',
      desc: 'Responde 50 preguntas correctas seguidas en Trivia.',
      emoji: '🌍',
      dificultad: 'medio',
      xp: 500,
      monedas: 60,
    ),
    AchievementItem(
      key: 'wordle_racha_3',
      nombre: 'Mente Constante',
      desc: 'Resuelve el Eco-Wordle por 3 días consecutivos.',
      emoji: '📆',
      dificultad: 'medio',
      xp: 200,
      monedas: 30,
    ),
    AchievementItem(
      key: 'likes_diez',
      nombre: 'Influencer Ecológico',
      desc: 'Consigue un total de 10 likes acumulados en tus publicaciones.',
      emoji: '💖',
      dificultad: 'medio',
      xp: 180,
      monedas: 25,
    ),
    AchievementItem(
      key: 'ducha_eficiente',
      nombre: 'Héroe del Agua',
      desc: 'Completa un Speedrun de la Ducha en menos de 5 minutos.',
      emoji: '⏱️',
      dificultad: 'medio',
      xp: 220,
      monedas: 35,
    ),
    AchievementItem(
      key: 'cinco_canjes',
      nombre: 'Cliente Frecuente',
      desc: 'Canjea un total de 5 recompensas en la tienda.',
      emoji: '🎟️',
      dificultad: 'medio',
      xp: 250,
      monedas: 40,
    ),
    AchievementItem(
      key: 'sopa_rapida',
      nombre: 'Rastreador Veloz',
      desc: 'Resuelve una Sopa de Letras en menos de 2 minutos.',
      emoji: '⚡',
      dificultad: 'medio',
      xp: 200,
      monedas: 30,
    ),
    AchievementItem(
      key: 'conector_sin_error',
      nombre: 'Conexión Perfecta',
      desc: 'Completa un Eco-Conector sin equivocarte de combinación.',
      emoji: '💎',
      dificultad: 'medio',
      xp: 210,
      monedas: 35,
    ),
    AchievementItem(
      key: 'familia_activa',
      nombre: 'Clan Ecológico',
      desc: 'Que 3 miembros distintos suban evidencias el mismo día.',
      emoji: '👥',
      dificultad: 'medio',
      xp: 300,
      monedas: 45,
    ),

    // ==========================================
    // LOGROS DIFÍCILES (13) - Competitivos y Avanzados
    // ==========================================
    AchievementItem(
      key: 'multiples_evidencias',
      nombre: 'Cronista Verde',
      desc: 'Sube un total de 10 evidencias ecológicas.',
      emoji: '📸',
      dificultad: 'difícil',
      xp: 500,
      monedas: 100,
    ),
    AchievementItem(
      key: 'nivel_cinco',
      nombre: 'Eco Héroe',
      desc: 'Alcanza el nivel 5 de conciencia ecológica.',
      emoji: '🎖️',
      dificultad: 'difícil',
      xp: 400,
      monedas: 80,
    ),
    AchievementItem(
      key: 'nivel_diez',
      nombre: 'Eco Leyenda',
      desc: 'Alcanza el nivel 10 de conciencia ecológica.',
      emoji: '👑',
      dificultad: 'difícil',
      xp: 1000,
      monedas: 200,
    ),
    AchievementItem(
      key: 'monedas_cien',
      nombre: 'Rico en Ecología',
      desc: 'Acumula un balance activo de 100 monedas.',
      emoji: '💰',
      dificultad: 'difícil',
      xp: 500,
      monedas: 100,
    ),
    AchievementItem(
      key: 'jefe_aprobador',
      nombre: 'Eco Juez',
      desc: 'Como Jefe de Familia, aprueba 15 retos o canjes legítimos.',
      emoji: '⚖️',
      dificultad: 'difícil',
      xp: 400,
      monedas: 80,
    ),
    AchievementItem(
      key: 'trivia_75',
      nombre: 'Guardián del Ecosistema',
      desc: 'Responde 75 preguntas correctas seguidas en Trivia.',
      emoji: '🛡️',
      dificultad: 'difícil',
      xp: 750,
      monedas: 100,
    ),
    AchievementItem(
      key: 'trivia_100',
      nombre: 'Deidad de la Ecología',
      desc: 'Responde 100 preguntas correctas seguidas en Trivia.',
      emoji: '🔱',
      dificultad: 'difícil',
      xp: 1500,
      monedas: 200,
    ),
    AchievementItem(
      key: 'likes_cincuenta',
      nombre: 'Orgullo de la Familia',
      desc: 'Consigue 50 likes acumulados en tus evidencias aprobadas.',
      emoji: '✨',
      dificultad: 'difícil',
      xp: 600,
      monedas: 120,
    ),
    AchievementItem(
      key: 'record_ahorro_luz',
      nombre: 'Apaga la Tele',
      desc: 'Registra una boleta con un consumo (kWh) menor al mes anterior.',
      emoji: '📉',
      dificultad: 'difícil',
      xp: 700,
      monedas: 150,
    ),
    AchievementItem(
      key: 'record_ahorro_agua',
      nombre: 'Cierra la Llave',
      desc: 'Registra una boleta con un consumo (m³) menor al mes anterior.',
      emoji: '📉',
      dificultad: 'difícil',
      xp: 700,
      monedas: 150,
    ),
    AchievementItem(
      key: 'barra_familiar_100',
      nombre: 'Familia Suprema',
      desc: 'Lleva la Barra de Energía Familiar al 100% este mes.',
      emoji: '🔋',
      dificultad: 'difícil',
      xp: 800,
      monedas: 150,
    ),
    AchievementItem(
      key: 'wordle_perfect_month',
      nombre: 'Diccionario Viviente',
      desc: 'Completa todos los Eco-Wordles del mes sin fallar ninguno.',
      emoji: '📅',
      dificultad: 'difícil',
      xp: 900,
      monedas: 180,
    ),
    AchievementItem(
      key: 'puzzle_inmune',
      nombre: 'Clasificador Infalible',
      desc: 'Logra 3 partidas perfectas consecutivas en el Eco-Puzzle.',
      emoji: '🤖',
      dificultad: 'difícil',
      xp: 650,
      monedas: 130,
    ),
  ];

  final Map<String, String> _unlockedKeysWithDate = {};
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Merged list of catalog items with their unlocked states
  List<AchievementItem> get achievements {
    return _catalog.map((c) {
      final isUnlocked = _unlockedKeysWithDate.containsKey(c.key);
      final unlockedAtStr = _unlockedKeysWithDate[c.key];
      return c.copyWith(
        desbloqueado: isUnlocked,
        desbloqueadoEn: unlockedAtStr,
      );
    }).toList();
  }

  Future<void> loadForUser(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final unlocked = await _achievementService.getUnlockedAchievements(
        userId,
      );
      _unlockedKeysWithDate.clear();
      for (final row in unlocked) {
        final key = row['logro_key'] as String;
        final dateStr = row['desbloqueado_en'] as String? ?? '';
        _unlockedKeysWithDate[key] = dateStr;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading achievements: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkAndUnlock(
    String userId,
    String logroKey, {
    required AuthProvider authProvider,
  }) async {
    // If already unlocked locally, return immediately to save DB call
    if (_unlockedKeysWithDate.containsKey(logroKey)) return;

    try {
      // Check database to be double sure (prevents parallel/duplicate unlock races)
      final currentUnlocked = await _achievementService.getUnlockedAchievements(
        userId,
      );
      final keys = currentUnlocked.map((r) => r['logro_key'] as String).toSet();

      // Update local state in case it was out of sync
      _unlockedKeysWithDate.clear();
      for (final row in currentUnlocked) {
        final k = row['logro_key'] as String;
        final d = row['desbloqueado_en'] as String? ?? '';
        _unlockedKeysWithDate[k] = d;
      }

      if (keys.contains(logroKey)) {
        notifyListeners();
        return;
      }

      // Find the achievement item to get rewards and info
      final item = _catalog.firstWhere((c) => c.key == logroKey);

      // 1. Insert unlock into achievements table
      await _achievementService.unlockAchievement(userId, logroKey);

      // 2. Award rewards (XP/Monedas) in profiles table
      final leveledUp = await _taskService.rewardUser(
        userId,
        item.xp,
        item.monedas,
      );

      // 3. Write dynamic UI Notification
      final timeNow = DateTime.now().toIso8601String();
      await NotificationProvider.writeNotificationForUser(
        userId,
        NotificationItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_logro_$logroKey',
          title: '🏆 Logro Desbloqueado: ${item.nombre}',
          desc:
              '¡Genial! Desbloqueaste "${item.nombre}" y ganaste +${item.xp} XP y +${item.monedas} 🪙!',
          time: timeNow,
          iconCode: 'emoji_events',
          colorHex: '#F9A825',
        ),
      );

      // 4. If leveled up, write level up notification as well
      if (leveledUp) {
        await NotificationProvider.writeNotificationForUser(
          userId,
          NotificationItem(
            id: '${DateTime.now().millisecondsSinceEpoch}_nivel',
            title: '¡Subiste de nivel!',
            desc:
                '¡Felicidades! Has alcanzado un nuevo nivel por desbloquear el logro ${item.nombre}.',
            time: timeNow,
            iconCode: 'star',
            colorHex: '#1976D2',
          ),
        );
      }

      // 5. Refresh user profile (gives new XP, level, coins to screens)
      await authProvider.refreshProfile();

      // Update local cache
      _unlockedKeysWithDate[logroKey] = timeNow;
      notifyListeners();

      debugPrint('✓ Achievement unlocked successfully: $logroKey');
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
    }
  }

  void checkProfileAchievements(
    UserProfile profile,
    AuthProvider authProvider,
  ) {
    final userId = profile.id;
    if (profile.familyId != null && profile.familyId!.isNotEmpty) {
      checkAndUnlock(
        userId,
        'unirse_familia',
        authProvider: authProvider,
      ).ignore();
    }
    if (profile.nivel >= 5) {
      checkAndUnlock(
        userId,
        'nivel_cinco',
        authProvider: authProvider,
      ).ignore();
    }
    if (profile.nivel >= 10) {
      checkAndUnlock(userId, 'nivel_diez', authProvider: authProvider).ignore();
    }
    if (profile.monedas >= 100) {
      checkAndUnlock(
        userId,
        'monedas_cien',
        authProvider: authProvider,
      ).ignore();
    }
  }

  void clear() {
    _unlockedKeysWithDate.clear();
    notifyListeners();
  }
}
