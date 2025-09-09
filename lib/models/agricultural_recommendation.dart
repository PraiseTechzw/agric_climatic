class AgriculturalRecommendation {
  final String id;
  final String title;
  final String description;
  final String category;
  final String priority;
  final DateTime date;
  final String location;
  final String cropType;
  final List<String> actions;
  final Map<String, dynamic> conditions;
  final bool isRead;
  final DateTime createdAt;

  AgriculturalRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.date,
    required this.location,
    required this.cropType,
    required this.actions,
    required this.conditions,
    this.isRead = false,
    required this.createdAt,
  });

  factory AgriculturalRecommendation.fromJson(Map<String, dynamic> json) {
    return AgriculturalRecommendation(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      priority: json['priority'] ?? 'medium',
      date: DateTime.parse(json['date']),
      location: json['location'] ?? '',
      cropType: json['cropType'] ?? '',
      actions: List<String>.from(json['actions'] ?? []),
      conditions: Map<String, dynamic>.from(json['conditions'] ?? {}),
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'date': date.toIso8601String(),
      'location': location,
      'cropType': cropType,
      'actions': actions,
      'conditions': conditions,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  AgriculturalRecommendation copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? priority,
    DateTime? date,
    String? location,
    String? cropType,
    List<String>? actions,
    Map<String, dynamic>? conditions,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AgriculturalRecommendation(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      date: date ?? this.date,
      location: location ?? this.location,
      cropType: cropType ?? this.cropType,
      actions: actions ?? this.actions,
      conditions: conditions ?? this.conditions,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

