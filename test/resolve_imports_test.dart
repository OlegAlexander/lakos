import 'dart:io' as io;
import 'package:test/test.dart';
import 'package:lakos/resolve_imports.dart' as resolve_imports;
import 'package:lakos/get_package_location.dart' as gpl;
import 'package:path/path.dart' as path;

void main() {
  final testPackage = gpl.getPackageLocation('test', '1.14.3');
  final pathPackage = gpl.getPackageLocation('path', '1.7.0');

  test('Resolve relative file', () {
    var thisDartFile = io.File(path.join(testPackage.path, 'lib', 'src',
        'runner', 'browser', 'phantom_js.dart'));
    var relativeFile = '../executable_settings.dart';
    var resolvedFile = resolve_imports.resolveFile(thisDartFile, relativeFile);
    print(resolvedFile);
    expect(
        resolvedFile.path,
        path.join(testPackage.path, 'lib', 'src', 'runner',
            'executable_settings.dart'));
  });

  test('Resolve relative file from .', () {
    var relativeFile = 'resolve_imports.dart';
    var thisDartFile = io.File('./lib/graphviz.dart');
    var resolvedFile = resolve_imports.resolveFile(thisDartFile, relativeFile);
    print(resolvedFile);
    expect(resolvedFile.path, path.join('lib', 'resolve_imports.dart'));
  });

  test('find pubspec.yaml', () {
    var pubspecYaml = resolve_imports.findPubspecYaml(io.Directory('.'));
    expect(pubspecYaml, isNotNull);
    pubspecYaml = resolve_imports.findPubspecYaml(io.Directory('./lib'));
    expect(pubspecYaml, isNotNull);
    pubspecYaml = resolve_imports.findPubspecYaml(testPackage);
    expect(pubspecYaml, isNotNull);
    pubspecYaml = resolve_imports.findPubspecYaml(pathPackage);
    expect(pubspecYaml, isNotNull);
    pubspecYaml = resolve_imports.findPubspecYaml(io.Directory('..'));
    expect(pubspecYaml, isNull);
  });

  test('resolvePackageFileFromPubspecYaml', () {
    var pubspecYaml = resolve_imports.findPubspecYaml(io.Directory('.'));
    var resolvedPackageFile = resolve_imports.resolvePackageFileFromPubspecYaml(
        pubspecYaml, 'package:lakos/graphviz.dart');
    var pathParts = path.split(resolvedPackageFile.path);
    var lastThreeParts = path
        .joinAll(pathParts.sublist(pathParts.length - 3))
        .replaceAll('\\', '/');
    expect(lastThreeParts, 'lakos/lib/graphviz.dart');
  });
}
