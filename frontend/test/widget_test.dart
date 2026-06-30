import 'package:flutter_test/flutter_test.dart';
import 'package:fluentai/core/config.dart';

void main() {
  test('AppConfig exposes an API base URL', () {
    expect(AppConfig.apiBaseUrl, isNotEmpty);
  });
}
