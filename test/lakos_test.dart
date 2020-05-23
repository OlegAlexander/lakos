import 'dart:io' as io;
import 'dart:convert' as convert;
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:lakos/get_package_location.dart' as gpl;

const outDir = 'dot_images';

/// Run lakos dot and return the stdout.
/// Also save the stdout to a dot file and generate a png.
String runLakosDot(String rootDir, String outDir, String dotFilename) {
  var result =
      io.Process.runSync('dart', ['bin/lakos.dart', 'dot', '-d', rootDir]);

  io.File('$outDir/$dotFilename.dot').writeAsStringSync(result.stdout);
  var dotResult = io.Process.runSync('dot', [
    '-Tpng',
    '$outDir/$dotFilename.dot',
    '-Gdpi=300',
    '-o',
    '$outDir/$dotFilename.png'
  ]);

  print([dotResult.stdout, dotResult.stderr, dotResult.exitCode]);

  // Remove carriage returns on Windows
  var ls = convert.LineSplitter();
  var lines = ls.convert(result.stdout);
  return lines.join('\n');
}

void main() {
  io.Directory('dot_images').createSync();

  test('Invalid command', () {
    var result = io.Process.runSync('dart', ['bin/lakos.dart', 'INVALID']);
    expect(result.stderr.toString().split('\n')[1].trim(),
        'Could not find a command named "INVALID".');
    expect(result.exitCode, 255);
  });

  test('json_serializable', () {
    var packageLocation = gpl.getPackageLocation('json_serializable', '3.3.0');
    print(packageLocation);
    var result = runLakosDot(
        path.join(packageLocation.path, 'lib'), outDir, 'json_serializable');
    print(result);
  });

  test('test', () {
    var packageLocation = gpl.getPackageLocation('test', '1.14.3');
    print(packageLocation);
    var result =
        runLakosDot(path.join(packageLocation.path, 'lib'), outDir, 'test');
    print(result);
  });

  test('lakos', () {
    var packageLocation = io.Directory('.');
    print(packageLocation);
    var result = runLakosDot(packageLocation.path, outDir, 'lakos');
    print(result);
  });

  test('path', () {
    var packageLocation = gpl.getPackageLocation('path', '1.7.0');
    print(packageLocation);
    var result =
        runLakosDot(path.join(packageLocation.path, 'lib'), outDir, 'path');
    print(result);
  });

  test('args', () {
    var packageLocation = gpl.getPackageLocation('args', '1.6.0');
    print(packageLocation);
    var result =
        runLakosDot(path.join(packageLocation.path, 'lib'), outDir, 'args');
    print(result);
  });

  test('dart_code_metrics', () {
    var packageLocation = gpl.getPackageLocation('dart_code_metrics', '1.4.0');
    print(packageLocation);
    var result = runLakosDot(
        path.join(packageLocation.path, 'lib'), outDir, 'dart_code_metrics');
    print(result);
  });

  test('pub_cache', () {
    var packageLocation = gpl.getPackageLocation('pub_cache', '0.2.3');
    print(packageLocation);
    var result = runLakosDot(packageLocation.path, outDir, 'pub_cache');
    print(result);
    expect(result, '''
digraph "G" {
  label="";
  labelloc=top;
  style=rounded;
  subgraph "cluster~/pub_cache-0.2.3" {
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
  }
  "/pub_cache-0.2.3/example/list.dart" -> "/pub_cache-0.2.3/lib/pub_cache.dart";
  "/pub_cache-0.2.3/lib/pub_cache.dart" -> "/pub_cache-0.2.3/lib/src/impl.dart";
  "/pub_cache-0.2.3/lib/src/impl.dart" -> "/pub_cache-0.2.3/lib/pub_cache.dart";
  "/pub_cache-0.2.3/test/all.dart" -> "/pub_cache-0.2.3/test/pub_cache_test.dart";
  "/pub_cache-0.2.3/test/pub_cache_test.dart" -> "/pub_cache-0.2.3/lib/pub_cache.dart";
}
''');
  });
}
