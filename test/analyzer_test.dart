// Conclusion 5/2/20: Use a combination of parseFile and package_config resolve.
// Conclusion 5/3/20: Don't use analyzer at all. It's too slow vs just parsing import statements.
// Write your own resolver function using package_config.

import 'dart:io';
import 'dart:cli';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:test/test.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart';

const filePath =
    r'C:\Users\olega\AppData\Roaming\Pub\Cache\hosted\pub.dartlang.org\analyzer-0.39.8\lib\dart\analysis\utilities.dart';

void main() {
  test('AnalysisContextCollection', () {
    var includedPaths = [filePath];
    var collection = AnalysisContextCollection(includedPaths: includedPaths);
    for (var context in collection.contexts) {
      print(['root', context.contextRoot.root]);
      print(['packagesFile', context.contextRoot.packagesFile]);
      var currentSession = context.currentSession;
      var parsedUnit = currentSession.getParsedUnit(includedPaths[0]);
      var resolvedUnit = currentSession.getResolvedUnit(includedPaths[0]);
      for (var directive in parsedUnit.unit.directives) {
        print(directive);
      }

      var libElement = resolvedUnit.then((unit) => unit.libraryElement);
      var importedLibraries = libElement.then((lib) => lib.importedLibraries);
      importedLibraries.then((libs) => libs.forEach((lib) => print(lib)));
    }
  });

  test('AnalysisContextCollection getResolvedLibrary', () {
    var includedPaths = [
      r'C:\Users\olega\AppData\Roaming\Pub\Cache\hosted\pub.dartlang.org\test-1.14.2\lib\src\runner\browser\phantom_js.dart'
    ];
    var collection = AnalysisContextCollection(
        includedPaths: includedPaths,
        resourceProvider: PhysicalResourceProvider.INSTANCE);
    for (var context in collection.contexts) {
      print(['root', context.contextRoot.root]);
      var currentSession = context.currentSession;
      var resolvedLib = waitFor<ResolvedLibraryResult>(
          currentSession.getResolvedLibrary(includedPaths[0]));
      for (var lib in resolvedLib.element.importedLibraries) {
        print(lib.identifier); // This doesn't resolve packages, only files
      }
      // var packageResolver = PackageMapUriResolver(context.contextRoot.resourceProvider, packageMap);
    }
  });

  test('parseFile', () {
    var parsedFile =
        parseFile(path: filePath, featureSet: FeatureSet.fromEnableFlags([]));
    for (var directive in parsedFile.unit.directives) {
      print([directive.runtimeType, directive.childEntities]);
    }
  });

  test('findPackageConfigUri package scheme', () async {
    var uri = Uri(scheme: 'file', path: filePath);
    var packageConfig = await findPackageConfigUri(uri);
    var packageUri = Uri.parse('package:analyzer/src/string_source.dart');
    var fileUri = Uri.parse(
        'file:///C:/Users/olega/AppData/Roaming/Pub/Cache/hosted/pub.dartlang.org/analyzer-0.39.8/lib/src/string_source.dart');
    expect(packageConfig.resolve(packageUri), fileUri);
    expect(packageConfig.toPackageUri(fileUri), packageUri);
  });

  test('resolveFile', () async {
    var resolvedFile = resolveFile(path: filePath);
    var libElem = await resolvedFile.then((resFile) => resFile.libraryElement);
    for (var impLib in libElem.importedLibraries) {
      print(['Import', impLib, impLib.location]);
    }
    for (var expLib in libElem.exportedLibraries) {
      print(['Export', expLib, expLib.location]);
    }
  });
}
