class ClassInfo {
  final String date;
  final String time;
  final String title;
  final String imageUrl;

  ClassInfo({
    required this.date,
    required this.time,
    required this.title,
    this.imageUrl = 'assets/primer.jpg',
  });
}
