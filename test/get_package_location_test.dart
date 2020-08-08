import 'package:test/test.dart';
import 'get_package_location.dart';

void main() {
  test('getPackageLocation', () {
    var location = getPackageLocation('pub_cache', '0.2.3');
    expect(location, isNotNull);
    location = getPackageLocation('pub_cache', '0.2.12345');
    expect(location, isNull);
    location = getPackageLocation('pub_cacheeeeee', '0.2.3');
    expect(location, isNull);
  });
}
