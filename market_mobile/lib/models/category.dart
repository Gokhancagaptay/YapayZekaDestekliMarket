class Category {
  final String title;
  final String iconPath; // assets/icons/*.svg ya da .png
  const Category({required this.title, required this.iconPath});
}

const categories = <Category>[
  Category(title: 'Meyveler', iconPath: 'assets/icons/fruit.svg'),
  Category(title: 'Sebzeler', iconPath: 'assets/icons/vegetable.svg'),
  Category(title: 'İçecekler', iconPath: 'assets/icons/drink.svg'),
  Category(title: 'Atıştırmalıklar', iconPath: 'assets/icons/snack.svg'),
  // dilediğin kadar ekle...
];
