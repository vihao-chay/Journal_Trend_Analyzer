import 'publication_model.dart';

class PublicationPageResult {
  const PublicationPageResult({
    required this.publications,
    required this.totalCount,
    required this.page,
    required this.perPage,
  });

  final List<PublicationModel> publications;
  final int totalCount;
  final int page;
  final int perPage;

  int get totalPages {
    if (totalCount <= 0 || perPage <= 0) {
      return 0;
    }
    return (totalCount + perPage - 1) ~/ perPage;
  }

  bool get hasPrevious => page > 1;

  bool get hasNext => page < totalPages;
}
