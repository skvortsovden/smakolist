import 'package:uuid/uuid.dart';

class ShoppingItem {
  final String id;
  String name;
  double? quantity;
  String unit;
  bool checked;

  ShoppingItem({
    required this.id,
    required this.name,
    this.quantity,
    this.unit = '',
    this.checked = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'checked': checked,
      };

  factory ShoppingItem.fromJson(Map<String, dynamic> j) => ShoppingItem(
        id: j['id'] as String,
        name: j['name'] as String,
        quantity: (j['quantity'] as num?)?.toDouble(),
        unit: j['unit'] as String? ?? '',
        checked: j['checked'] as bool? ?? false,
      );
}

class ShoppingList {
  final String id;
  String name;
  final DateTime createdAt;
  List<ShoppingItem> items;

  ShoppingList({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.items,
  });

  static ShoppingList create({String? name}) {
    final now = DateTime.now();
    return ShoppingList(
      id: const Uuid().v4(),
      name: name ?? defaultName(now),
      createdAt: now,
      items: [],
    );
  }

  static String defaultName(DateTime dt) {
    const months = [
      '', 'січня', 'лютого', 'березня', 'квітня', 'травня', 'червня',
      'липня', 'серпня', 'вересня', 'жовтня', 'листопада', 'грудня',
    ];
    return '${dt.day} ${months[dt.month]}';
  }

  int get checkedCount => items.where((i) => i.checked).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory ShoppingList.fromJson(Map<String, dynamic> j) => ShoppingList(
        id: j['id'] as String,
        name: j['name'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        items: (j['items'] as List<dynamic>)
            .map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
