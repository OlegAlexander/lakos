// TODO: Write your own resolve function using package_config. Remove all analyzer code.

import 'dart:io' as io;
import 'dart:cli' as cli;
import 'package:analyzer/dart/analysis/utilities.dart' as analyzer_utilities;
import 'package:analyzer/dart/analysis/features.dart' as analyzer_features;
import 'package:analyzer/dart/ast/ast.dart' as analyzer_ast;
import 'package:package_config/package_config.dart' as package_config;

/// Parse import, export, library, and part directives.
List<analyzer_ast.Directive> parseDirectives(io.File dartFile) {
  var parsedFile = analyzer_utilities.parseFile(
      path: dartFile.path,
      featureSet: analyzer_features.FeatureSet.fromEnableFlags([]));
  return parsedFile.unit.directives;
}

package_config.PackageConfig findPackageConfigUriSync(io.Directory rootDir) {
  return cli.waitFor<package_config.PackageConfig>(package_config
      .findPackageConfigUri(Uri(scheme: 'file', path: rootDir.path)));
}

Map<String, io.File> resolveDirectiveToFile(
    analyzer_ast.Directive directive,
    package_config.PackageConfig packageConfig,
    io.File thisDartFile,
    String thisPackageName) {
  var supportedDirectives = ['import', 'export'];
  var keyword = directive.keyword.toString();
  if (!supportedDirectives.contains(keyword)) {
    return null; // library and part directives are not supported
  }

  var directiveUri = Uri.parse(directive.childEntities
      .elementAt(1)
      .toString()
      .replaceAll("'", '')
      .replaceAll('"', '')); // Trim the quotes!

  switch (directiveUri.scheme) {
    case 'package':
      var resolvedUri = packageConfig.resolve(directiveUri);
      return {keyword: io.File.fromUri(resolvedUri)};

    case 'dart':
      directiveUri = Uri(
          scheme: 'package',
          path:
              '${directiveUri.path}/${directiveUri.path}.dart'); // Pretend it's a package!
      var resolvedUri = packageConfig.resolve(directiveUri);
      return {keyword: io.File.fromUri(resolvedUri)};

    case '':
      var thisDartFileUri = Uri.file(thisDartFile.path);
      var resolvedUri = thisDartFileUri.resolve(directiveUri.path);
      return {keyword: io.File.fromUri(resolvedUri)};

    default:
      return null; // Don't support dart: scheme
  }
}

void usage(io.Directory rootDir) {
  var packageConfig = findPackageConfigUriSync(rootDir);
  print(packageConfig);
  var entities = rootDir.listSync(recursive: true, followLinks: false);
  var dartFiles = entities
      .whereType<io.File>()
      .where((file) => file.path.endsWith('.dart'));

  for (var dartFile in dartFiles) {
    var packageName = packageConfig.packageOf(Uri.file(dartFile.path)).name;
    print('dartFile: ${dartFile.path}');
    var directives = parseDirectives(dartFile);
    for (var directive in directives) {
      print('    $directive');
      var resolvedFile = resolveDirectiveToFile(
          directive, packageConfig, dartFile, packageName);
      print('    $resolvedFile\n');
    }
  }
}
