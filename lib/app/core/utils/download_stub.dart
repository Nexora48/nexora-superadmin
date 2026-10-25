/// Non-web builds cannot save a file from here; callers fall back to showing the text.
Future<bool> downloadText(
  String filename,
  String content, {
  String mime = 'text/csv',
}) async => false;
