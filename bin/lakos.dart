// dart lakos.dart "C:\Users\olega\Documents\Dart\linter" | dot -Tsvg -o linter.svg
// dart lakos.dart "C:\Users\olega\Documents\Dart\hauberk\lib\src\engine" | dot -Tpng -Gdpi=300 -o hauberk.png

import 'dart:io' as io;
import 'dart:convert' as convert;
import 'package:path/path.dart' as path;
import 'package:gviz/gviz.dart' as gviz;

String parseImportLine(String line) {
  var openQuote = false;
  var importPath = '';
  for (var char in line.split('')) {
    if (openQuote == false && (char == "'" || char == '"')) {
      openQuote = true;
      continue;
    }
    if (openQuote == true && (char == "'" || char == '"')) {
      break;
    }
    if (openQuote == true) {
      importPath += char;
    }
  }
  return importPath;
}

String generateDotGraph(Map<String, List<String>> dartFiles) {
  var graph = gviz.Gviz();
  // Add nodes
  for (var file in dartFiles.keys) {
    graph.addNode(file);
  }
  // Add edges
  for (var source in dartFiles.keys) {
    for (var target in dartFiles[source]) {
      graph.addEdge(source, target);
    }
  }
  return graph.toString();
}

String getPrettyJSONString(jsonObject) {
  return convert.JsonEncoder.withIndent('    ').convert(jsonObject);
}

void main(List<String> args) {
  var rootDir = io.Directory(args[0]);
  var dartFiles = <String, List<String>>{};
  var entities = rootDir.listSync(recursive: true, followLinks: false);
  for (var entity in entities) {
    if (entity.path.endsWith('.dart')) {
      var dartFileForwardSlashes = entity.path.replaceAll('\\', '/');
      var rootDirForwardSlashes = rootDir.path.replaceAll('\\', '/');
      var dartFile =
          dartFileForwardSlashes.replaceFirst(rootDirForwardSlashes + '/', '');
      dartFiles[path.withoutExtension(dartFile)] = [];

      // Grab the imports from the dart file
      var lines = io.File(entity.path).readAsLinesSync();
      for (var line in lines) {
        var trimmedLine = line.trim();
        if (trimmedLine.startsWith('import')) {
          var parsedImportLine = parseImportLine(trimmedLine);
          // Don't support dart: and package: yet
          if (parsedImportLine.startsWith('dart:') ||
              parsedImportLine.startsWith('package:')) {
            continue;
          }
          var uri = Uri.file(dartFile);
          var resolvedUri = uri.resolve(parsedImportLine).toString();
          // Only add files that exist--account for imports inside strings, etc.
          if (io.File(rootDir.path + "/" + resolvedUri).existsSync()) {
            dartFiles[path.withoutExtension(dartFile)]
                .add(path.withoutExtension(resolvedUri));
          }
        }
      }
    }
  }

  var jsonText = getPrettyJSONString(dartFiles);
  // print(jsonText);

  var dotString = generateDotGraph(dartFiles);
  print(dotString);
}
