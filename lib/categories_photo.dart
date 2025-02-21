class CategoriesPhoto {
  String imageUrl;
  String label;

  CategoriesPhoto(this.imageUrl, this.label);

  static List<CategoriesPhoto> samples = [
    CategoriesPhoto('brain.jpg', 'LOGO'),
    CategoriesPhoto('eye.png', 'Eye - hand coordination'),
    CategoriesPhoto('bell.png', 'Ear - hand coordination'),
    CategoriesPhoto('brain.png', 'Memory'),
    CategoriesPhoto('lightbulb.png', 'Logic'),
  ];
}
