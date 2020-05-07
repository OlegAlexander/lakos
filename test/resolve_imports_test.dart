import 'dart:io' as io;
import 'package:test/test.dart';
import 'package:lakos/resolve_imports.dart' as resolve_imports;
import 'package:lakos/get_package_location.dart' as gpl;
import 'package:path/path.dart' as path;

void main() {
  final testPackage = gpl.getPackageLocation('test', '1.14.2');
  final pathPackage = gpl.getPackageLocation('path', '1.7.0');
  final thisDartFile = io.File(path.join(
      testPackage.path, 'lib', 'src', 'runner', 'browser', 'phantom_js.dart'));
  final packageConfig =
      resolve_imports.findPackageConfigUriSync(thisDartFile.parent);

  test('findPackageConfigUriSync', () {
    var packageConfig =
        resolve_imports.findPackageConfigUriSync(thisDartFile.parent);
    print(packageConfig);
    expect(packageConfig, isNotNull);
  });

  test('findPackageConfigUriSync from .', () {
    var packageConfig =
        resolve_imports.findPackageConfigUriSync(io.Directory('.'));
    print(packageConfig.packages
        .where((package) => package.name == 'lakos')
        .first
        .root);
    print(packageConfig.packages
        .where((package) => package.name == 'io')
        .first
        .root);
    expect(packageConfig, isNotNull);
  });

  test('findPackageConfigUriSync null', () {
    var packageConfig =
        resolve_imports.findPackageConfigUriSync(io.Directory('C:/'));
    print(packageConfig);
    expect(packageConfig, isNull);
  });

  test('Resolve relative file', () {
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

  test('Resolve package file from .', () {
    var packageFile = 'package:lakos/graphviz.dart';
    var thisDirectory = io.Directory('.');
    var packageConfig = resolve_imports.findPackageConfigUriSync(thisDirectory);
    var resolvedFile =
        resolve_imports.resolvePackage(packageConfig, packageFile);
    print(resolvedFile);
    expect(resolvedFile.path,
        path.join(thisDirectory.absolute.parent.path, 'lib', 'graphviz.dart'));
  });

  test('Resolve package file', () {
    var packageFile = 'package:path/path.dart';
    var resolvedFile =
        resolve_imports.resolvePackage(packageConfig, packageFile);
    print(resolvedFile);
    print(path.isWithin(thisDartFile.parent.path, resolvedFile.path));
    expect(resolvedFile.path, path.join(pathPackage.path, 'lib', 'path.dart'));
  });

  test('Resolve package file null', () {
    var packageFile = 'package:i/dont/exist.dart';
    var resolvedFile =
        resolve_imports.resolvePackage(packageConfig, packageFile);
    print(resolvedFile);
    expect(resolvedFile, isNull);
  });
}