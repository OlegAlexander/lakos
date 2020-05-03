// Conclusion: Use a combination of parseFile and package_config resolve.

import 'package:test/test.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:package_config/package_config.dart';

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

  test('parseFile', () {
    var parsedFile =
        parseFile(path: filePath, featureSet: FeatureSet.fromEnableFlags([]));
    for (var directive in parsedFile.unit.directives) {
      print(directive.childEntities);
    }
  });

  test('PackageConfig', () async {
    var packageConfig =
        await findPackageConfigUri(Uri(scheme: 'file', path: filePath));
    var packageUri =
        Uri(scheme: 'package', path: 'analyzer/src/string_source.dart');
    var fileUri = Uri(
        scheme: 'file',
        path:
            'C:/Users/olega/AppData/Roaming/Pub/Cache/hosted/pub.dartlang.org/analyzer-0.39.8/lib/src/string_source.dart');
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
