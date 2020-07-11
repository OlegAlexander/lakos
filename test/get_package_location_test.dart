import 'package:test/test.dart';
import 'get_package_location.dart' as gpl;

void main() {
  test('getPackageLocation', () {
    var location = gpl.getPackageLocation('pub_cache', '0.2.3');
    expect(location, isNotNull);
    location = gpl.getPackageLocation('pub_cache', '0.2.12345');
    expect(location, isNull);
    location = gpl.getPackageLocation('pub_cacheeeeee', '0.2.3');
    expect(location, isNull);
  });
}
