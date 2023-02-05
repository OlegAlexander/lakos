import 'package:test/test.dart';
import 'get_package_location.dart';

void main() {
  test('getPackageLocation', () {
    var location = getPackageLocation('path');
    expect(location, isNotNull);
    location = getPackageLocation('pathhhhhhhhhhhh');
    expect(location, isNull);
  });
}
