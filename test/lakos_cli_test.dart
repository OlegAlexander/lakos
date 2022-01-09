import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart';
import 'get_package_location.dart';
import '../bin/lakos.dart' show ExitCode;

const outDir = 'dot_images';
const lakos = 'bin/lakos.dart';
const dpi = 200;
var packages = {
  '.': ExitCode.ok.index,
  'path': ExitCode.dependencyCycleDetected.index,
  'args': ExitCode.dependencyCycleDetected.index,
  'directed_graph': ExitCode.ok.index,
  'glob': ExitCode.ok.index,
  'test': ExitCode.ok.index,
  'pub_cache': ExitCode.dependencyCycleDetected.index,
  'string_scanner': ExitCode.dependencyCycleDetected.index
};

void main() {
  Directory(outDir).createSync();

  test('InvalidOption', () {
    var result = Process.runSync('dart', [lakos, '--invalid']);
    expect(result.exitCode, ExitCode.invalidOption.index);

    result = Process.runSync('dart', [lakos, '--layout', 'INVALID']);
    expect(result.exitCode, ExitCode.invalidOption.index);
  });

  test('NoRootDirectorySpecified', () {
    var result = Process.runSync('dart', [lakos]);
    expect(result.exitCode, ExitCode.noRootDirectorySpecified.index);
  });

  test('BuildModelFailed', () {
    var result = Process.runSync('dart', [lakos, 'i/dont/exist']);
    expect(result.exitCode, ExitCode.buildModelFailed.index);
  });

  test('generate dot graphs -- force forward slashes on Windows', () {
    for (var package in packages.keys) {
      var packageLocation = getPackageLocation(package)!;
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
          'dot', ['-Tpng', dotFilename, '-Gdpi=$dpi', '-o', pngFilename, '-v']);
      print(dotResult.stderr
          .toString()
          .split('\n')
          .where((line) => line.startsWith('fontname')));
      expect(dotResult.exitCode, ExitCode.ok.index);
    }
  });

  test('metrics_no_test Pipe to dot -- node color --cycles-allowed', () {
    for (var package in packages.keys) {
      var packageLocation = getPackageLocation(package)!;
      var outputFilename = package == '.' ? 'lakos' : package;
      var dotFilename =
          join(outDir, '$outputFilename.metrics_no_test_pipe_color.dot');
      var pngFilename =
          join(outDir, '$outputFilename.metrics_no_test_pipe_color.png');

      var lakosDotCommand = [
        lakos,
        '-m',
        '-i',
        'test/**',
        '--cycles-allowed',
        packageLocation.path
      ];
      print(lakosDotCommand.join(' '));
      var lakosDotResult = Process.runSync('dart', lakosDotCommand);
      expect(lakosDotResult.exitCode, ExitCode.ok.index);

      // Manually save the stdout to a file
      File(dotFilename).writeAsStringSync(lakosDotResult.stdout);

      var dotCommand = [
        '-Tpng',
        dotFilename,
        '-Gdpi=$dpi',
        '-Nfillcolor=steelblue2:steelblue4',
        '-Nfontcolor=white',
        '-Ngradientangle=270',
        '-o',
        pngFilename,
        '-v'
      ];
      print(dotCommand.join(' '));
      var dotResult = Process.runSync('dot', dotCommand);
      print(dotResult.stderr
          .toString()
          .split('\n')
          .where((line) => line.startsWith('fontname')));
      expect(dotResult.exitCode, ExitCode.ok.index);
    }
  });

  test('generate dot graphs--metrics--no test', () {
    for (var package in packages.keys) {
      var packageLocation = getPackageLocation(package)!;
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
      expect(dotResult.exitCode, ExitCode.ok.index);
    }
  });

  test('generate dot graphs--no test--no tree', () {
    for (var package in packages.keys) {
      var packageLocation = getPackageLocation(package)!;
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
      expect(dotResult.exitCode, ExitCode.ok.index);
    }
  });

  test('generate dot graphs--no test--node metrics', () {
    for (var package in packages.keys) {
      var packageLocation = getPackageLocation(package)!;
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
      expect(dotResult.exitCode, ExitCode.ok.index);
    }
  });

  test('generate dot graphs--no test--layout LR', () {
    for (var package in packages.keys) {
      var packageLocation = getPackageLocation(package)!;
      var outputFilename = package == '.' ? 'lakos' : package;
      var dotFilename = join(outDir, '$outputFilename.no_test_lr.dot');
      var pngFilename = join(outDir, '$outputFilename.no_test_lr.png');

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

      var dotCommand = [
        '-Tpng',
        dotFilename,
        '-Grankdir=LR',
        '-Gdpi=$dpi',
        '-o',
        pngFilename
      ];
      print(dotCommand.join(' '));
      var dotResult = Process.runSync('dot', dotCommand);
      expect(dotResult.exitCode, ExitCode.ok.index);
    }
  });

  test('generate json files--metrics--no test', () {
    for (var package in packages.keys) {
      var packageLocation = getPackageLocation(package)!;
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
