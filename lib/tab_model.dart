class TabModel {
  int id;
  String url;
  String? title;
  String? content;
  final bool isIncognito;

  TabModel({
    required this.id, 
    required this.url,
    this.title,
    this.content,
    this.isIncognito = false
  });
}