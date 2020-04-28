import 'dart:io' as io;
import 'dart:convert' as convert;
import 'package:test/test.dart';
import 'package:pub_cache/pub_cache.dart' as pub_cache;
import 'package:path/path.dart' as path;

const outDir = 'dot_images';

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

/// Run lakos dot and return the stdout.
/// Also save the stdout to a dot file and generate a png.
String runLakosDot(String rootDir, String outDir, String dotFilename) {
  var result = io.Process.runSync('dart', ['bin/lakos.dart', 'dot', rootDir]);

  io.File('$outDir/$dotFilename.dot').writeAsStringSync(result.stdout);
  io.Process.runSync('dot', [
    '-Tpng',
    '$outDir/$dotFilename.dot',
    '-Gdpi=300',
    '-o',
    '$outDir/$dotFilename.png'
  ]);

  // Remove carriage returns on Windows
  var ls = convert.LineSplitter();
  var lines = ls.convert(result.stdout);
  return lines.join('\n');
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
    var location = getPackageLocation('pub_cache', '0.2.3');
    expect(location, isNotNull);
    location = getPackageLocation('pub_cache', '0.2.12345');
    expect(location, isNull);
    location = getPackageLocation('pub_cacheeeeee', '0.2.3');
    expect(location, isNull);
  });

  test('json_serializable', () {
    var packageLocation = getPackageLocation('json_serializable', '3.3.0');
    var result = runLakosDot(
        path.join(packageLocation.path, 'lib'), outDir, 'json_serializable');
    print(result);
  });

  test('test', () {
    var packageLocation = getPackageLocation('test', '1.14.2');
    var result =
        runLakosDot(path.join(packageLocation.path, 'lib'), outDir, 'test');
    print(result);
  });

  test('pub_cache', () {
    var packageLocation = getPackageLocation('pub_cache', '0.2.3');
    var result = runLakosDot(packageLocation.path, outDir, 'pub_cache');
    print(result);
    expect(result, r'''
digraph "G" {
  label="";
  labelloc=top;
  style=rounded;
  subgraph "cluster~\pub_cache-0.2.3" {
    label="pub_cache-0.2.3";
    subgraph "cluster~/pub_cache-0.2.3/example" {
      label="example";
      "/pub_cache-0.2.3/example/list.dart" [label="list"];
    }
    subgraph "cluster~/pub_cache-0.2.3/lib" {
      label="lib";
      "/pub_cache-0.2.3/lib/pub_cache.dart" [label="pub_cache"];
      subgraph "cluster~/pub_cache-0.2.3/lib/src" {
        label="src";
        "/pub_cache-0.2.3/lib/src/impl.dart" [label="impl"];
      }
    }
    subgraph "cluster~/pub_cache-0.2.3/test" {
      label="test";
      "/pub_cache-0.2.3/test/all.dart" [label="all"];
      "/pub_cache-0.2.3/test/pub_cache_test.dart" [label="pub_cache_test"];
    }
    subgraph "cluster~/pub_cache-0.2.3/tool" {
      label="tool";
    }
  }
  "/pub_cache-0.2.3/lib/pub_cache.dart" -> "/pub_cache-0.2.3/lib/src/impl.dart";
  "/pub_cache-0.2.3/lib/src/impl.dart" -> "/pub_cache-0.2.3/lib/pub_cache.dart";
  "/pub_cache-0.2.3/test/all.dart" -> "/pub_cache-0.2.3/test/pub_cache_test.dart";
}
''');
  });
}
