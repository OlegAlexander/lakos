import 'package:test/test.dart';
import 'get_package_location.dart';

void main() {
  test('getPackageLocation', () {
    var location = getPackageLocation('pub_cache');
    expect(location, isNotNull);
    location = getPackageLocation('pub_cacheeeeee');
    expect(location, isNull);
  });
}
