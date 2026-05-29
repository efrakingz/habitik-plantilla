class UserProfile {
  final String id;
  final String email;
  final String nombre;
  final String avatarLetra;
  final String avatarColor;
  final String? avatarUrl;
  final String rol;
  final String? familyId;
  final int xp;
  final int nivel;
  final int monedas;
  final int triviaCorrectCount;
  final String? triviaLastUpdated;
  final String? dailyBonusClaimedAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.nombre,
    required this.avatarLetra,
    required this.avatarColor,
    this.avatarUrl,
    required this.rol,
    this.familyId,
    this.xp = 0,
    this.nivel = 1,
    this.monedas = 0,
    this.triviaCorrectCount = 0,
    this.triviaLastUpdated,
    this.dailyBonusClaimedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] ?? '',
    email: json['email'] ?? '',
    nombre: json['nombre'] ?? 'Usuario',
    avatarLetra: json['avatar_letra'] ?? 'U',
    avatarColor: json['avatar_color'] ?? '#2e7d32',
    avatarUrl: json['avatar_url'],
    rol: json['rol'] ?? 'miembro',
    familyId: json['family_id'],
    xp: json['xp'] ?? 0,
    nivel: json['nivel'] ?? 1,
    monedas: json['monedas'] ?? 0,
    triviaCorrectCount: json['trivia_correct_count'] ?? 0,
    triviaLastUpdated: json['trivia_last_updated']?.toString(),
    dailyBonusClaimedAt: json['daily_bonus_claimed_at']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'nombre': nombre,
    'avatar_letra': avatarLetra,
    'avatar_color': avatarColor,
    'avatar_url': avatarUrl,
    'rol': rol,
    'family_id': familyId,
    'xp': xp,
    'nivel': nivel,
    'monedas': monedas,
    'trivia_correct_count': triviaCorrectCount,
    'trivia_last_updated': triviaLastUpdated,
    'daily_bonus_claimed_at': dailyBonusClaimedAt,
  };

  UserProfile copyWith({
    String? id,
    String? email,
    String? nombre,
    String? avatarLetra,
    String? avatarColor,
    String? avatarUrl,
    String? rol,
    String? familyId,
    int? xp,
    int? nivel,
    int? monedas,
    int? triviaCorrectCount,
    String? triviaLastUpdated,
    String? dailyBonusClaimedAt,
  }) => UserProfile(
    id: id ?? this.id,
    email: email ?? this.email,
    nombre: nombre ?? this.nombre,
    avatarLetra: avatarLetra ?? this.avatarLetra,
    avatarColor: avatarColor ?? this.avatarColor,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    rol: rol ?? this.rol,
    familyId: familyId ?? this.familyId,
    xp: xp ?? this.xp,
    nivel: nivel ?? this.nivel,
    monedas: monedas ?? this.monedas,
    triviaCorrectCount: triviaCorrectCount ?? this.triviaCorrectCount,
    triviaLastUpdated: triviaLastUpdated ?? this.triviaLastUpdated,
    dailyBonusClaimedAt: dailyBonusClaimedAt ?? this.dailyBonusClaimedAt,
  );
}

class FamilyMember {
  final String id;
  final String nombre;
  final String rol;
  final int xp;
  final int nivel;
  final String avatar;
  final String color;
  final String? avatarUrl;
  final int triviaCorrectCount;
  final String? triviaLastUpdated;

  FamilyMember({
    this.id = '',
    required this.nombre,
    required this.rol,
    required this.xp,
    required this.nivel,
    required this.avatar,
    required this.color,
    this.avatarUrl,
    this.triviaCorrectCount = 0,
    this.triviaLastUpdated,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
    id: json['id'] ?? '',
    nombre: json['nombre'] ?? 'Usuario',
    rol: json['rol'] ?? 'miembro',
    xp: json['xp'] ?? 0,
    nivel: json['nivel'] ?? 1,
    avatar: json['avatar_letra']?.toString() ?? 'U',
    color: json['avatar_color']?.toString() ?? '#2e7d32',
    avatarUrl: json['avatar_url']?.toString(),
    triviaCorrectCount: json['trivia_correct_count'] ?? 0,
    triviaLastUpdated: json['trivia_last_updated']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'rol': rol,
    'xp': xp,
    'nivel': nivel,
    'avatar_letra': avatar,
    'avatar_color': color,
    'trivia_correct_count': triviaCorrectCount,
    'trivia_last_updated': triviaLastUpdated,
  };

  FamilyMember withAvatarUrl(String? url) => FamilyMember(
    id: id, nombre: nombre, rol: rol, xp: xp, nivel: nivel,
    avatar: avatar, color: color, avatarUrl: url,
    triviaCorrectCount: triviaCorrectCount,
    triviaLastUpdated: triviaLastUpdated,
  );
}

class Evidence {
  final String id;
  final String? userId;
  final String? familyId;
  final String autor;
  final String avatar;
  final String color;
  final String? avatarUrl;   // <-- cached from SP per userId
  final String accion;
  final String desc;
  int likes;
  final String tiempo;
  final int xp;
  final String emoji;
  final String? imagen;

  Evidence({
    this.id = '',
    this.userId,
    this.familyId,
    required this.autor,
    required this.avatar,
    required this.color,
    this.avatarUrl,
    required this.accion,
    required this.desc,
    required this.likes,
    required this.tiempo,
    required this.xp,
    required this.emoji,
    this.imagen,
  });

  factory Evidence.fromJson(Map<String, dynamic> json) => Evidence(
    id: json['id'] ?? '',
    userId: json['user_id'],
    familyId: json['family_id'],
    autor: json['autor'] ?? '',
    avatar: json['avatar'] ?? 'U',
    color: json['color'] ?? '#2e7d32',
    accion: json['accion'] ?? '',
    desc: json['descripcion'] ?? '',
    likes: json['likes'] ?? 0,
    tiempo: json['created_at'] ?? '',
    xp: json['xp'] ?? 0,
    emoji: json['emoji'] ?? '🌟',
    imagen: json['imagen_url'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    if (userId != null) 'user_id': userId,
    if (familyId != null) 'family_id': familyId,
    'autor': autor,
    'avatar': avatar,
    'color': color,
    'accion': accion,
    'descripcion': desc,
    'likes': likes,
    'created_at': tiempo,
    'xp': xp,
    'emoji': emoji,
    if (imagen != null) 'imagen_url': imagen,
  };
}

class TaskItem {
  final String id;
  final String? familyId;
  String tarea;
  String asignado;
  bool hecho;
  int xp;
  String tipo;

  TaskItem({
    required this.id,
    this.familyId,
    required this.tarea,
    required this.asignado,
    required this.hecho,
    required this.xp,
    required this.tipo,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
    id: json['id']?.toString() ?? '',
    familyId: json['family_id']?.toString(),
    tarea: json['tarea']?.toString() ?? '',
    asignado: json['asignado_id']?.toString() ?? '',
    hecho: json['hecho'] == true || json['hecho'] == 1 || json['hecho'] == 'true',
    xp: int.tryParse(json['xp']?.toString() ?? '0') ?? 0,
    tipo: json['tipo']?.toString() ?? 'general',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    if (familyId != null) 'family_id': familyId,
    'tarea': tarea,
    'asignado_id': asignado,
    'hecho': hecho,
    'xp': xp,
    'tipo': tipo,
  };
}

class BillData {
  final String id;
  final String? familyId;
  final String tipo;
  final String consumo;
  final String monto;
  final String periodo;
  final String? empresa;
  final String? cuenta;
  final String? tarifa;
  final String? imagenUrl;

  BillData({
    this.id = '',
    this.familyId,
    this.tipo = 'luz',
    required this.consumo,
    required this.monto,
    required this.periodo,
    required this.empresa,
    required this.cuenta,
    required this.tarifa,
    this.imagenUrl,
  });

  factory BillData.fromJson(Map<String, dynamic> json) => BillData(
    id: json['id']?.toString() ?? '',
    familyId: json['family_id']?.toString(),
    tipo: json['tipo']?.toString() ?? 'luz',
    consumo: json['consumo']?.toString() ?? '',
    monto: json['monto']?.toString() ?? '',
    periodo: json['periodo']?.toString() ?? '',
    empresa: json['empresa']?.toString() ?? '',
    cuenta: json['cuenta']?.toString() ?? '',
    tarifa: json['tarifa']?.toString() ?? '',
    imagenUrl: json['imagen_url']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    if (familyId != null) 'family_id': familyId,
    'tipo': tipo,
    'consumo': consumo,
    'monto': monto,
    'periodo': periodo,
    'empresa': empresa,
    'cuenta': cuenta,
    'tarifa': tarifa,
    if (imagenUrl != null) 'imagen_url': imagenUrl,
  };
}

class RewardItem {
  final int id;
  final String? familyId;
  final String titulo;
  final int costo;
  final String descripcion;
  final String emoji;
  bool disponible;
  final String creador;
  DateTime? lastRedeemedAt;

  RewardItem({
    required this.id,
    this.familyId,
    required this.titulo,
    required this.costo,
    required this.descripcion,
    this.emoji = '🎁',
    required this.disponible,
    required this.creador,
    this.lastRedeemedAt,
  });

  factory RewardItem.fromJson(Map<String, dynamic> json) => RewardItem(
    id: json['id'] ?? 0,
    familyId: json['family_id'],
    titulo: json['titulo'] ?? '',
    costo: json['costo'] ?? 0,
    descripcion: json['descripcion'] ?? '',
    emoji: json['emoji'] ?? '🎁',
    disponible: json['disponible'] ?? true,
    creador: json['creador_id'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    if (familyId != null) 'family_id': familyId,
    'titulo': titulo,
    'costo': costo,
    'descripcion': descripcion,
    'emoji': emoji,
    'disponible': disponible,
    'creador_id': creador,
  };
}

class ChallengeType {
  final String id;
  final String emoji;
  final String titulo;
  final String desc;
  final int xp;
  final int monedas;
  final String color;

  ChallengeType({
    required this.id,
    required this.emoji,
    required this.titulo,
    required this.desc,
    required this.xp,
    required this.monedas,
    required this.color,
  });

  factory ChallengeType.fromJson(Map<String, dynamic> json) => ChallengeType(
    id: json['id']?.toString() ?? '',
    emoji: json['emoji'] ?? '🎯',
    titulo: json['titulo'] ?? '',
    desc: json['desc'] ?? '',
    xp: json['xp'] ?? 0,
    monedas: json['monedas'] ?? 0,
    color: json['color'] ?? '#000000',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'emoji': emoji,
    'titulo': titulo,
    'desc': desc,
    'xp': xp,
    'monedas': monedas,
    'color': color,
  };
}

class PendingValidation {
  final int id;
  final String userId;
  final String usuario;
  final String avatar;
  final String color;
  final String reto;
  final String hora;
  final int xp;
  final int monedas;
  final List<String> evidencias;
  final bool requiereEvidencia;

  PendingValidation({
    required this.id,
    required this.userId,
    required this.usuario,
    required this.avatar,
    required this.color,
    required this.reto,
    required this.hora,
    required this.xp,
    required this.monedas,
    required this.evidencias,
    required this.requiereEvidencia,
  });

  factory PendingValidation.fromJson(Map<String, dynamic> json) => PendingValidation(
    id: json['id'] ?? 0,
    userId: json['user_id'] ?? '',
    usuario: json['usuario'] ?? '',
    avatar: json['avatar'] ?? 'U',
    color: json['color'] ?? '#000000',
    reto: json['reto'] ?? '',
    hora: json['hora'] ?? '',
    xp: json['xp'] ?? 0,
    monedas: json['monedas'] ?? 0,
    evidencias: List<String>.from(json['evidencias'] ?? []),
    requiereEvidencia: json['requiere_evidencia'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'usuario': usuario,
    'avatar': avatar,
    'color': color,
    'reto': reto,
    'hora': hora,
    'xp': xp,
    'monedas': monedas,
    'evidencias': evidencias,
    'requiere_evidencia': requiereEvidencia,
  };
}

class AchievementItem {
  final String key;
  final String nombre;
  final String desc;
  final String emoji;
  final String dificultad;
  final int xp;
  final int monedas;
  final bool desbloqueado;
  final String? desbloqueadoEn;

  AchievementItem({
    required this.key,
    required this.nombre,
    required this.desc,
    required this.emoji,
    required this.dificultad,
    required this.xp,
    required this.monedas,
    this.desbloqueado = false,
    this.desbloqueadoEn,
  });

  AchievementItem copyWith({
    bool? desbloqueado,
    String? desbloqueadoEn,
  }) => AchievementItem(
    key: key,
    nombre: nombre,
    desc: desc,
    emoji: emoji,
    dificultad: dificultad,
    xp: xp,
    monedas: monedas,
    desbloqueado: desbloqueado ?? this.desbloqueado,
    desbloqueadoEn: desbloqueadoEn ?? this.desbloqueadoEn,
  );

  factory AchievementItem.fromJson(Map<String, dynamic> json) => AchievementItem(
    key: json['logro_key'] ?? '',
    nombre: json['nombre'] ?? '',
    desc: json['desc'] ?? '',
    emoji: json['emoji'] ?? '🏆',
    dificultad: json['dificultad'] ?? 'fácil',
    xp: json['xp'] ?? 0,
    monedas: json['monedas'] ?? 0,
    desbloqueado: json['desbloqueado'] ?? false,
    desbloqueadoEn: json['desbloqueado_en'],
  );

  Map<String, dynamic> toJson() => {
    'logro_key': key,
    'nombre': nombre,
    'desc': desc,
    'emoji': emoji,
    'dificultad': dificultad,
    'xp': xp,
    'monedas': monedas,
    'desbloqueado': desbloqueado,
    'desbloqueado_en': desbloqueadoEn,
  };
}

class TriviaQuestion {
  final String pregunta;
  final List<String> opciones;
  final int correcta;

  TriviaQuestion({
    required this.pregunta,
    required this.opciones,
    required this.correcta,
  });
}
