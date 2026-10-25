import 'package:chess_master/app/project_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creator destination is the requested HTTPS website', () {
    final Uri website = Uri.parse(ProjectLinks.website);
    expect(website.scheme, 'https');
    expect(website.host, 'sanskarin.github.io');
    expect(website.hasQuery, isFalse);
    expect(website.hasFragment, isFalse);
    expect(website.userInfo, isEmpty);
  });

  test('source remains available at the canonical project repository', () {
    expect(ProjectLinks.repository, 'https://github.com/sanskarIN/Chess');
  });
}
