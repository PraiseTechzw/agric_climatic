class Farm {
  final String id;
  final String name;
  final String location;
  final String crop;
  final double area;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Farm({
    required this.id,
    required this.name,
    required this.location,
    required this.crop,
    required this.area,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      crop: json['crop'] ?? '',
      area: (json['area'] ?? 0).toDouble(),
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'crop': crop,
      'area': area,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Farm copyWith({
    String? id,
    String? name,
    String? location,
    String? crop,
    double? area,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Farm(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      crop: crop ?? this.crop,
      area: area ?? this.area,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
