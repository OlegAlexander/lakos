import 'dart:io';
import 'package:test/test.dart';
import 'package:lakos/src/build_model.dart';

void main() {
  test('buildModel rootDir does not exist', () {
    try {
      buildModel(Directory('/i/dont/exist'));
    } catch (e) {
      expect(e, isA<FileSystemException>());
    }
  });

  test('buildModel pubspec.yaml not found', () {
    try {
      if (Platform.isWindows) {
        buildModel(Directory('C:/'));
      } else {
        buildModel(Directory('/'));
      }
    } catch (e) {
      expect(e, isA<PubspecYamlNotFoundException>());
    }
  });

  test('invalid glob string', () {
    try {
      buildModel(Directory('.'), ignoreGlob: '{invalid');
    } catch (e) {
      expect(e, isA<FormatException>());
    }
  });

  test('parseImportLine', () {
    var importLines = '''
import 'dart:io';
import 'package:path/path.dart' as path;
import "package:lakos/resolve_imports.dart" as resolve_imports;
import  "metrics.dart"  as metrics;
import 'package:' 
'''
        .split('\n')
        .map((line) => parseImportLine(line));
    expect(importLines, [
      'dart:io',
      'package:path/path.dart',
      'package:lakos/resolve_imports.dart',
      'metrics.dart',
      null,
      null
    ]);
  });
}
