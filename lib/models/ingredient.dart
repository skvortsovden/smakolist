const List<String> kDefaultIngredients = [
  // Овочі
  'картопля', 'морква', 'цибуля', 'часник', 'броколі', 'капуста',
  'помідор', 'огірок', 'перець', 'баклажан', 'кабачок', 'буряк',
  'шпинат', 'салат', 'гриби', 'кукурудза', 'горошок', 'селера',
  // М'ясо / риба
  'курятина', 'яловичина', 'свинина', 'індичка', 'риба', 'тунець',
  'лосось', 'оселедець', 'морепродукти', 'бекон', 'ковбаса',
  // Молочні / яйця
  'яйця', 'молоко', 'вершки', 'масло', 'сир', 'сметана',
  'кефір', 'йогурт', 'пармезан', 'моцарела', 'фета',
  // Крупи / борошно
  'рис', 'макарони', 'гречка', 'вівсянка', 'пшоно', 'булгур',
  'кускус', 'борошно', 'манка', 'перловка',
  // Бобові
  'квасоля', 'горох', 'сочевиця', 'нут',
  // Фрукти / ягоди
  'яблуко', 'банан', 'лимон', 'апельсин', 'полуниця', 'чорниця',
  'виноград', 'груша', 'персик', 'слива',
  // Горіхи / насіння
  'горіхи', 'мигдаль', 'кешью', 'арахіс', 'насіння соняшнику',
  // Соуси / приправи
  'оливкова олія', 'соняшникова олія', 'сіль', 'перець мелений',
  'цукор', 'мед', 'соєвий соус', 'томатна паста', 'майонез',
  'гірчиця', 'оцет', 'паприка', 'куркума', 'кмин', 'базилік',
  'орегано', 'розмарин', 'петрушка', 'кріп', 'кінза',
  // Інше
  'бульйон', 'вода', 'дріжджі', 'розпушувач', 'сода', 'шоколад',
  'какао', 'ваніль', 'крохмаль',
];

const List<String> kDefaultUnits = [
  'г', 'кг', 'мл', 'л', 'шт', 'ст.л.', 'ч.л.', 'пучок', 'щіпка',
];

const List<String> kDefaultCategories = [
  'паста', 'суп', 'салат', 'риба',
];

class RecipeIngredient {
  final String name;
  final double? quantity;
  final String unit;

  const RecipeIngredient({
    required this.name,
    this.quantity,
    this.unit = 'г',
  });

  RecipeIngredient copyWith({
    String? name,
    double? quantity,
    String? unit,
    bool clearQuantity = false,
  }) {
    return RecipeIngredient(
      name: name ?? this.name,
      quantity: clearQuantity ? null : (quantity ?? this.quantity),
      unit: unit ?? this.unit,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
      };

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      RecipeIngredient(
        name: json['name'] as String,
        quantity: (json['quantity'] as num?)?.toDouble(),
        unit: json['unit'] as String? ?? 'г',
      );
}
