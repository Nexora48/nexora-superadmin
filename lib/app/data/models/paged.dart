/// One page of a paginated list (data + meta from the API envelope).
class Paged<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int total;

  const Paged({required this.items, required this.page, required this.pageSize, required this.total});

  int get totalPages => pageSize == 0 ? 0 : (total / pageSize).ceil();
  bool get isEmpty => items.isEmpty;
}
