const List<String> kDefaultIngredients = [
  // Овочі
  'Картопля', 'Морква', 'Цибуля', 'Часник', 'Броколі', 'Капуста',
  'Помідор', 'Огірок', 'Перець', 'Баклажан', 'Кабачок', 'Буряк',
  'Шпинат', 'Салат', 'Гриби', 'Кукурудза', 'Горошок', 'Селера',
  // М'ясо / риба
  'Курятина', 'Яловичина', 'Свинина', 'Індичка', 'Риба', 'Тунець',
  'Лосось', 'Оселедець', 'Морепродукти', 'Бекон', 'Ковбаса',
  // Молочні / яйця
  'Яйця', 'Молоко', 'Вершки', 'Масло', 'Сир', 'Сметана',
  'Кефір', 'Йогурт', 'Пармезан', 'Моцарела', 'Фета',
  // Крупи / борошно
  'Рис', 'Макарони', 'Гречка', 'Вівсянка', 'Пшоно', 'Булгур',
  'Кускус', 'Борошно', 'Манка', 'Перловка',
  // Бобові
  'Квасоля', 'Горох', 'Сочевиця', 'Нут',
  // Фрукти / ягоди
  'Яблуко', 'Банан', 'Лимон', 'Апельсин', 'Полуниця', 'Чорниця',
  'Виноград', 'Груша', 'Персик', 'Слива',
  // Горіхи / насіння
  'Горіхи', 'Мигдаль', 'Кешью', 'Арахіс', 'Насіння соняшнику',
  // Соуси / приправи
  'Оливкова олія', 'Соняшникова олія', 'Сіль', 'Перець мелений',
  'Цукор', 'Мед', 'Соєвий соус', 'Томатна паста', 'Майонез',
  'Гірчиця', 'Оцет', 'Паприка', 'Куркума', 'Кмин', 'Базилік',
  'Орегано', 'Розмарин', 'Петрушка', 'Кріп', 'Кінза',
  // Інше
  'Бульйон', 'Вода', 'Дріжджі', 'Розпушувач', 'Сода', 'Шоколад',
  'Какао', 'Ваніль', 'Крохмаль',
];

const List<String> kDefaultUnits = [
  'г', 'кг', 'мл', 'л', 'шт', 'ст.л.', 'ч.л.', 'пучок', 'щіпка',
];

const List<String> kDefaultCategories = [
  'Паста', 'Суп', 'Салат', 'М\'ясо', 'Риба', 'Каша', 'Десерт',
  'Випічка', 'Сніданок', 'Напій',
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
