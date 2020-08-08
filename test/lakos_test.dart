import 'dart:io';
import 'dart:convert';
import 'package:test/test.dart';
import 'package:path/path.dart';
import 'get_package_location.dart';

const outDir = 'dot_images';

/// Run lakos dot and return the stdout.
/// Also save the stdout to a dot file and generate a png.
String runLakosDot(String rootDir, String outDir, String dotFilename) {
  var result = Process.runSync('dart', ['bin/lakos.dart', rootDir]);

  print(['lakosResult', result.stdout, result.stderr, result.exitCode]);

  File('$outDir/$dotFilename.dot').writeAsStringSync(result.stdout);
  var dotResult = Process.runSync('dot', [
    '-Tpng',
    '$outDir/$dotFilename.dot',
    '-Gdpi=300',
    '-o',
    '$outDir/$dotFilename.png'
  ]);

  print(['dotResult', dotResult.stdout, dotResult.stderr, dotResult.exitCode]);

  // Remove carriage returns on Windows
  var ls = LineSplitter();
  var lines = ls.convert(result.stdout);
  return lines.join('\n');
}

void main() {
  Directory('dot_images').createSync();

  test('Invalid option', () {
    var result = Process.runSync('dart', ['bin/lakos.dart', '--invalid']);
    print([result.stdout, result.stderr, result.exitCode]);
    expect(result.stdout.toString().split('\n')[0].trim(),
        'FormatException: Could not find an option named "invalid".');
    expect(result.exitCode, 1);
  });

  test('No directory specified', () {
    var result = Process.runSync('dart', ['bin/lakos.dart']);
    print([result.stdout, result.stderr, result.exitCode]);
    expect(result.stdout.toString().split('\n')[0].trim(),
        'No root directory specified.');
    expect(result.exitCode, 2);
  });

  test('json_serializable', () {
    var packageLocation = getPackageLocation('json_serializable', '3.3.0');
    print(packageLocation);
    var result = runLakosDot(
        join(packageLocation.path, 'lib'), outDir, 'json_serializable');
    expect(result, isNotEmpty);
  });

  test('test', () {
    var packageLocation = getPackageLocation('test', '1.14.3');
    print(packageLocation);
    var result = runLakosDot(join(packageLocation.path, 'lib'), outDir, 'test');
    expect(result, isNotEmpty);
  });

  test('lakos', () {
    var packageLocation = Directory('.');
    print(packageLocation);
    var result = runLakosDot(packageLocation.path, outDir, 'lakos');
    expect(result, isNotEmpty);
  });

  test('path', () {
    var packageLocation = getPackageLocation('path', '1.7.0');
    print(packageLocation);
    var result = runLakosDot(join(packageLocation.path, 'lib'), outDir, 'path');
    expect(result, isNotEmpty);
  });

  test('args', () {
    var packageLocation = getPackageLocation('args', '1.6.0');
    print(packageLocation);
    var result = runLakosDot(join(packageLocation.path, 'lib'), outDir, 'args');
    expect(result, isNotEmpty);
  });

  test('dart_code_metrics', () {
    var packageLocation = getPackageLocation('dart_code_metrics', '1.4.0');
    print(packageLocation);
    var result = runLakosDot(
        join(packageLocation.path, 'lib'), outDir, 'dart_code_metrics');
    expect(result, isNotEmpty);
  });

  test('directed_graph', () {
    var packageLocation = getPackageLocation('directed_graph', '0.1.3');
    print(packageLocation);
    var result = runLakosDot(packageLocation.path, outDir, 'directed_graph');
    expect(result, isNotEmpty);
  });

  test('pub_cache', () {
    var packageLocation = getPackageLocation('pub_cache', '0.2.3');
    print(packageLocation);
    var result = runLakosDot(packageLocation.path, outDir, 'pub_cache');
    expect(result, isNotEmpty);
  });
}
