class Task {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime? endDate;
  bool isCompleted;
  final DateTime createdAt;
  final String? category;
  final String? description;
  final bool isEvent;

  Task({
    required this.id,
    required this.title,
    required this.startDate,
    this.endDate,
    this.isCompleted = false,
    required this.createdAt,
    this.category,
    this.description,
    this.isEvent = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
    'category': category,
    'description': description,
    'isEvent': isEvent,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    startDate: json['startDate'] != null
        ? DateTime.parse(json['startDate'])
        : DateTime.parse(json['date']),
    endDate: json['endDate'] != null
        ? DateTime.parse(json['endDate'])
        : (json['date'] != null ? DateTime.parse(json['date']) : null),
    isCompleted: json['isCompleted'],
    createdAt: DateTime.parse(json['createdAt']),
    category: json['category'],
    description: json['description'],
    isEvent: json['isEvent'] ?? false,
  );
}
