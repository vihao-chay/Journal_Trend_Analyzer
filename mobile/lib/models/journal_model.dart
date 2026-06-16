class JournalModel {
  const JournalModel({required this.displayName, required this.worksCount});

  final String displayName;
  final int worksCount;

  factory JournalModel.fromMap(Map<String, dynamic> map) {
    return JournalModel(
      displayName: map['display_name'] as String? ?? 'Unknown Journal',
      worksCount: _asInt(map['works_count']),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
