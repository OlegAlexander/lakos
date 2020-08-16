import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart';
import 'get_package_location.dart';
import '../bin/lakos.dart' show ExitCode;

const outDir = 'dot_images';
const lakos = 'bin/lakos.dart';
var packages = {
  '.': ExitCode.Ok.index,
  'path': ExitCode.DependencyCycleDetected.index,
  'args': ExitCode.DependencyCycleDetected.index,
  'directed_graph': ExitCode.Ok.index,
  'glob': ExitCode.Ok.index,
  'test': ExitCode.Ok.index,
  'pub_cache': ExitCode.DependencyCycleDetected.index,
  'json_serializable': ExitCode.DependencyCycleDetected.index,
  'string_scanner': ExitCode.DependencyCycleDetected.index
};

void main() {
  Directory(outDir).createSync();

  test('InvalidOption', () {
    var result = Process.runSync('dart', [lakos, '--invalid']);
    expect(result.exitCode, ExitCode.InvalidOption.index);

    result = Process.runSync('dart', [lakos, '--layout', 'INVALID']);
    expect(result.exitCode, ExitCode.InvalidOption.index);
  });

  test('NoRootDirectorySpecified', () {
    var result = Process.runSync('dart', [lakos]);
    expect(result.exitCode, ExitCode.NoRootDirectorySpecified.index);
  });

  test('BuildModelFailed', () {
    var result = Process.runSync('dart', [lakos, 'i/dont/exist']);
    expect(result.exitCode, ExitCode.BuildModelFailed.index);
  });

  test('generate dot graphs', () {
    for (var package in packages.keys) {
      var packageLocation = getPackageLocation(package);
      var outputFilename = package == '.' ? 'lakos' : package;
      var dotFilename = join(outDir, '$outputFilename.dot');
      var pngFilename = join(outDir, '$outputFilename.png');

      var lakosDotCommand = [lakos, '-o', dotFilename, packageLocation.path];
      print(lakosDotCommand.join(' '));
      var lakosDotResult = Process.runSync('dart', lakosDotCommand);
      expect(lakosDotResult.exitCode, packages[package]);

      var dotResult = Process.runSync(
          'dot', ['-Tpng', dotFilename, '-Gdpi=300', '-o', pngFilename]);
      expect(dotResult.exitCode, ExitCode.Ok.index);
    }
  });

  test('generate dot graphs--no test', () {
    for (var package in packages.keys) {
      var packageLocation = getPackageLocation(package);
      var outputFilename = package == '.' ? 'lakos' : package;
      var dotFilename = join(outDir, '$outputFilename.no_test.dot');
      var pngFilename = join(outDir, '$outputFilename.no_test.png');

      var lakosDotCommand = [
        lakos,
        '-o',
        dotFilename,
        '-i',
        'test/**',
        packageLocation.path
      ];
      print(lakosDotCommand.join(' '));
      var lakosDotResult = Process.runSync('dart', lakosDotCommand);
      expect(lakosDotResult.exitCode, packages[package]);

      var dotResult = Process.runSync(
          'dot', ['-Tpng', dotFilename, '-Gdpi=300', '-o', pngFilename]);
      expect(dotResult.exitCode, ExitCode.Ok.index);
    }
  });

  test('generate dot graphs--no test--no tree--no-metrics', () {
    for (var package in packages.keys) {
      var packageLocation = getPackageLocation(package);
      var outputFilename = package == '.' ? 'lakos' : package;
      var dotFilename =
          join(outDir, '$outputFilename.no_test_no_tree_no_metrics.dot');
      var pngFilename =
          join(outDir, '$outputFilename.no_test_no_tree_no_metrics.png');

      var lakosDotCommand = [
        lakos,
        '--no-tree',
        '--no-metrics',
        '-o',
        dotFilename,
        '-i',
        'test/**',
        packageLocation.path
      ];
      print(lakosDotCommand.join(' '));
      var lakosDotResult = Process.runSync('dart', lakosDotCommand);
      expect(lakosDotResult.exitCode,
          ExitCode.Ok.index); // With --no-metrics expect OK

      var dotResult = Process.runSync(
          'dot', ['-Tpng', dotFilename, '-Gdpi=300', '-o', pngFilename]);
      expect(dotResult.exitCode, ExitCode.Ok.index);
    }
  });

  test('generate dot graphs--no test--node metrics', () {
    for (var package in packages.keys) {
      var packageLocation = getPackageLocation(package);
      var outputFilename = package == '.' ? 'lakos' : package;
      var dotFilename =
          join(outDir, '$outputFilename.no_test_node_metrics.dot');
      var pngFilename =
          join(outDir, '$outputFilename.no_test_node_metrics.png');

      var lakosDotCommand = [
        lakos,
        '-o',
        dotFilename,
        '-i',
        'test/**',
        '--node-metrics',
        packageLocation.path
      ];
      print(lakosDotCommand.join(' '));
      var lakosDotResult = Process.runSync('dart', lakosDotCommand);
      expect(lakosDotResult.exitCode, packages[package]);

      var dotResult = Process.runSync(
          'dot', ['-Tpng', dotFilename, '-Gdpi=300', '-o', pngFilename]);
      expect(dotResult.exitCode, ExitCode.Ok.index);
    }
  });

  test('generate dot graphs--no test--no metrics--layout LR', () {
    for (var package in packages.keys) {
      var packageLocation = getPackageLocation(package);
      var outputFilename = package == '.' ? 'lakos' : package;
      var dotFilename =
          join(outDir, '$outputFilename.no_test_no_metrics_lr.dot');
      var pngFilename =
          join(outDir, '$outputFilename.no_test_no_metrics_lr.png');

      var lakosDotCommand = [
        lakos,
        '-o',
        dotFilename,
        '-i',
        'test/**',
        '--no-metrics',
        '-l',
        'LR',
        packageLocation.path
      ];
      print(lakosDotCommand.join(' '));
      var lakosDotResult = Process.runSync('dart', lakosDotCommand);
      expect(lakosDotResult.exitCode,
          ExitCode.Ok.index); // With --no-metrics expect OK

      var dotResult = Process.runSync(
          'dot', ['-Tpng', dotFilename, '-Gdpi=300', '-o', pngFilename]);
      expect(dotResult.exitCode, ExitCode.Ok.index);
    }
  });

  test('generate json files--no test', () {
    for (var package in packages.keys) {
      var packageLocation = getPackageLocation(package);
      var outputFilename = package == '.' ? 'lakos' : package;
      var jsonFilename = join(outDir, '$outputFilename.no_test.json');

      var lakosJsonCommand = [
        lakos,
        '-f',
        'json',
        '-o',
        jsonFilename,
        '-i',
        'test/**',
        packageLocation.path
      ];
      print(lakosJsonCommand.join(' '));
      var result = Process.runSync('dart', lakosJsonCommand);
      expect(result.exitCode, packages[package]);
    }
  });
}
