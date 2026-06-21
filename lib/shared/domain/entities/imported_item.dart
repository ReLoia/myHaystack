class ImportedItem {
  final String name;
  final String privateKey;
  final int color;
  final String? emoji;

  ImportedItem({
    required this.name,
    required this.privateKey,
    required this.color,
    this.emoji,
  });
}
