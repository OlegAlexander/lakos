import 'dart:io' as io;
import 'package:test/test.dart';
import 'package:pub_cache/pub_cache.dart' as pub_cache;

/// Return the location of the package on disk.
/// Or return null if the package doesn't exist in the pub cache.
io.Directory getPackageLocation(String packageName, String packageVersion) {
  var cache = pub_cache.PubCache();
  var allVersions = cache.getAllPackageVersions(packageName);
  for (var version in allVersions) {
    if (version.version.toString() == packageVersion) {
      return version.resolve().location;
    }
  }
  return null;
}

void main() {
  io.Directory('dot_images').createSync();

  test('Wrong number of arguments.', () {
    var result = io.Process.runSync('dart', ['bin/lakos.dart']);
    expect(result.stdout.toString().split('\n')[0].trim(),
        'Wrong number of arguments.');
    expect(result.exitCode, 1);
  });

  test('Invalid mode', () {
    var result = io.Process.runSync('dart', ['bin/lakos.dart', 'beast', '.']);
    expect(
        result.stdout.toString().split('\n')[0].trim(), 'Invalid mode: beast');
    expect(result.exitCode, 1);
  });

  test('getPackageLocation', () {
    var gviz = getPackageLocation('gviz', '0.3.0');
    expect(gviz, isNotNull);
    gviz = getPackageLocation('gviz', '0.3.123');
    expect(gviz, isNull);
    gviz = getPackageLocation('gvizzz', '0.3.0');
    expect(gviz, isNull);
  });

  test('json_serializable', () {
    var packageLocation = getPackageLocation('json_serializable', '3.3.0');
    expect(packageLocation, isNotNull);
    var result = io.Process.runSync(
        'dart', ['bin/lakos.dart', 'dot', packageLocation.path + '\\lib']);
    print(result.stdout);
    io.Process.runSync(
        'dart',
        [
          'bin/lakos.dart',
          'dot',
          packageLocation.path + '\\lib',
          '|',
          'dot',
          '-Tpng',
          '-Gdpi=300',
          '-o',
          'dot_images/json_serializable.png'
        ],
        runInShell: true);
  });

  test('pub_cache', () {
    var packageLocation = getPackageLocation('pub_cache', '0.2.3');
    expect(packageLocation, isNotNull);
    var result = io.Process.runSync(
        'dart', ['bin/lakos.dart', 'dot', packageLocation.path]);
    print(result.stdout);
    io.Process.runSync(
        'dart',
        [
          'bin/lakos.dart',
          'dot',
          packageLocation.path,
          '|',
          'dot',
          '-Tpng',
          '-Gdpi=300',
          '-o',
          'dot_images/pub_cache.png'
        ],
        runInShell: true);
  });

  test('test', () {
    var packageLocation = getPackageLocation('test', '1.14.2');
    expect(packageLocation, isNotNull);
    var result = io.Process.runSync(
        'dart', ['bin/lakos.dart', 'dot', packageLocation.path + '\\lib']);
    print(result.stdout);
    io.Process.runSync(
        'dart',
        [
          'bin/lakos.dart',
          'dot',
          packageLocation.path + '\\lib',
          '|',
          'dot',
          '-Tpng',
          '-Gdpi=300',
          '-o',
          'dot_images/test.png'
        ],
        runInShell: true);
  });
}
