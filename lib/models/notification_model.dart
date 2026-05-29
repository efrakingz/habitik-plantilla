class NotificationItem {
  final String id;
  final String title;
  final String desc;
  final String time;
  final String iconCode;
  final String colorHex;
  bool read;

  NotificationItem({
    required this.id,
    required this.title,
    required this.desc,
    required this.time,
    required this.iconCode,
    required this.colorHex,
    this.read = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    desc: json['desc_text']?.toString() ?? json['desc']?.toString() ?? '',
    time: json['time']?.toString() ?? json['created_at']?.toString() ?? '',
    iconCode: json['icon_code']?.toString() ?? 'notifications',
    colorHex: json['color_hex']?.toString() ?? '#388E3C',
    read: json['is_read'] ?? json['read'] == true,
  );


  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'desc_text': desc,
    'time': time,
    'icon_code': iconCode,
    'color_hex': colorHex,
    'is_read': read,
  };
}
