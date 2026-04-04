class BookModel {
  final int? id;
  final String name;
  final DateTime createdAt;
  final double cashIn;
  final double cashOut;

  BookModel({
    this.id,
    required this.name,
    required this.createdAt,
    this.cashIn = 0.0,
    this.cashOut = 0.0,
  });

  double get balance => cashIn - cashOut;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BookModel.fromMap(Map<String, dynamic> map) {
    return BookModel(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['createdAt']),
      cashIn: (map['cashIn'] ?? 0.0).toDouble(),
      cashOut: (map['cashOut'] ?? 0.0).toDouble(),
    );
  }
}
