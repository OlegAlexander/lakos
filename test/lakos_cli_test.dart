import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart';
import 'get_package_location.dart';
import '../bin/lakos.dart' show ExitCode;

const outDir = 'dot_images';
const lakos = 'bin/lakos.dart';
const dpi = '200';
var packages = {
  '.': ExitCode.Ok.index,
  'path': ExitCode.DependencyCycleDetected.index,
  'args': ExitCode.DependencyCycleDetected.index,
  'directed_graph': ExitCode.DependencyCycleDetected.index,
  'glob': ExitCode.Ok.index,
  'test': ExitCode.Ok.index,
  'pub_cache': ExitCode.DependencyCycleDetected.index,
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

  test('generate dot graphs -- force forward slashes on Windows', () {
    for (var package in packages.keys) {
      var packageLocation = getPackageLocation(package);
      packageLocation = Directory(
          packageLocation.path.replaceAll('\\', '/')); // Force forward slashes
      var outputFilename = package == '.' ? 'lakos' : package;
      var dotFilename = join(outDir, '$outputFilename.dot');
      var pngFilename = join(outDir, '$outputFilename.png');

      var lakosDotCommand = [lakos, '-o', dotFilename, packageLocation.path];
      print(lakosDotCommand.join(' '));
      var lakosDotResult = Process.runSync('dart', lakosDotCommand);
      expect(lakosDotResult.exitCode, packages[package]);

      var dotResult = Process.runSync(
          'dot', ['-Tpng', dotFilename, '-Gdpi=$dpi', '-o', pngFilename]);
      expect(dotResult.exitCode, ExitCode.Ok.index);
    }
  });

  test('Pipe to dot -- node color -- font --cycles-allowed', () {
    for (var package in packages.keys) {
      var packageLocation = getPackageLocation(package);
      var outputFilename = package == '.' ? 'lakos' : package;
      var dotFilename = join(outDir, '$outputFilename.pipe_font_color.dot');
      var pngFilename = join(outDir, '$outputFilename.pipe_font_color.png');

      var lakosDotCommand = [
        lakos,
        '-c',
        '#f6e0b8:#c5a867',
        '--font',
        'Cambria',
        '--cycles-allowed',
        packageLocation.path
      ];
      print(lakosDotCommand.join(' '));
      var lakosDotResult = Process.runSync('dart', lakosDotCommand);
      expect(lakosDotResult.exitCode, ExitCode.Ok.index);

      // Manually save the stdout to a file
      File(dotFilename).writeAsStringSync(lakosDotResult.stdout);

      var dotResult = Process.runSync(
          'dot', ['-Tpng', dotFilename, '-Gdpi=$dpi', '-o', pngFilename]);
      print(dotResult.stderr);
      expect(dotResult.exitCode, ExitCode.Ok.index);
    }
  });

  test('generate dot graphs--metrics--no test', () {
    for (var package in packages.keys) {
      var packageLocation = getPackageLocation(package);
      var outputFilename = package == '.' ? 'lakos' : package;
      var dotFilename = join(outDir, '$outputFilename.metrics_no_test.dot');
      var pngFilename = join(outDir, '$outputFilename.metrics_no_test.png');

      var lakosDotCommand = [
        lakos,
        '-o',
        dotFilename,
        '-m',
        '-i',
        'test/**',
        packageLocation.path
      ];
      print(lakosDotCommand.join(' '));
      var lakosDotResult = Process.runSync('dart', lakosDotCommand);
      expect(lakosDotResult.exitCode, packages[package]);

      var dotResult = Process.runSync(
          'dot', ['-Tpng', dotFilename, '-Gdpi=$dpi', '-o', pngFilename]);
      expect(dotResult.exitCode, ExitCode.Ok.index);
    }
  });

  test('generate dot graphs--no test--no tree', () {
    for (var package in packages.keys) {
      var packageLocation = getPackageLocation(package);
      var outputFilename = package == '.' ? 'lakos' : package;
      var dotFilename = join(outDir, '$outputFilename.no_test_no_tree.dot');
      var pngFilename = join(outDir, '$outputFilename.no_test_no_tree.png');

      var lakosDotCommand = [
        lakos,
        '--no-tree',
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
          'dot', ['-Tpng', dotFilename, '-Gdpi=$dpi', '-o', pngFilename]);
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
        '-m',
        '-i',
        'test/**',
        '--node-metrics',
        packageLocation.path
      ];
      print(lakosDotCommand.join(' '));
      var lakosDotResult = Process.runSync('dart', lakosDotCommand);
      expect(lakosDotResult.exitCode, packages[package]);

      var dotResult = Process.runSync(
          'dot', ['-Tpng', dotFilename, '-Gdpi=$dpi', '-o', pngFilename]);
      expect(dotResult.exitCode, ExitCode.Ok.index);
    }
  });

  test('generate dot graphs--no test--layout LR', () {
    for (var package in packages.keys) {
      var packageLocation = getPackageLocation(package);
      var outputFilename = package == '.' ? 'lakos' : package;
      var dotFilename = join(outDir, '$outputFilename.no_test_lr.dot');
      var pngFilename = join(outDir, '$outputFilename.no_test_lr.png');

      var lakosDotCommand = [
        lakos,
        '-o',
        dotFilename,
        '-i',
        'test/**',
        '-l',
        'LR',
        packageLocation.path
      ];
      print(lakosDotCommand.join(' '));
      var lakosDotResult = Process.runSync('dart', lakosDotCommand);
      expect(lakosDotResult.exitCode, packages[package]);

      var dotResult = Process.runSync(
          'dot', ['-Tpng', dotFilename, '-Gdpi=$dpi', '-o', pngFilename]);
      expect(dotResult.exitCode, ExitCode.Ok.index);
    }
  });

  test('generate json files--metrics--no test', () {
    for (var package in packages.keys) {
      var packageLocation = getPackageLocation(package);
      var outputFilename = package == '.' ? 'lakos' : package;
      var jsonFilename = join(outDir, '$outputFilename.metrics_no_test.json');

      var lakosJsonCommand = [
        lakos,
        '-f',
        'json',
        '-o',
        jsonFilename,
        '-m',
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
