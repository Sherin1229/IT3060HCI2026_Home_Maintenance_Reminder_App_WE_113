import 'package:flutter_test/flutter_test.dart';

import 'package:homiq/config/app_router.dart';

void main() {
  test('Application starts on the splash route', () {
    expect(AppRouter.router.routeInformationProvider.value.uri.path, '/splash');
  });
}
