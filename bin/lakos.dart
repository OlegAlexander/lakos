// dart lakos.dart "C:\Users\olega\Documents\Dart\linter" | dot -Tsvg -o linter.svg
// dart lakos.dart "C:\Users\olega\Documents\Dart\hauberk\lib\src\engine" | dot -Tpng -Gdpi=300 -o hauberk.png

import 'dart:io' as io;
import 'dart:convert' as convert;
import 'package:path/path.dart' as path;
import 'package:lakos/graphviz.dart' as gv;

const usage = '''
Usage: lakos <mode> <rootDir>
Available modes:
  - dot: Print dependency graph in Graphviz dot format
  - metrics: Print dependency graph metrics in json format''';

const modes = ['dot', 'metrics'];

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
  var graph = gv.DigraphSimple('G', 'Dependency Graph');
  // Add nodes
  for (var file in dartFiles.keys) {
    graph.nodes.add(gv.Node(file, path.basenameWithoutExtension(file)));
  }
  // Add edges
  for (var source in dartFiles.keys) {
    for (var target in dartFiles[source]) {
      graph.edges.add(gv.Edge(source, target));
    }
  }
  return graph.toString();
}

String getPrettyJSONString(jsonObject) {
  return convert.JsonEncoder.withIndent('    ').convert(jsonObject);
}

void main(List<String> args) {
  if (args.length != 2) {
    print('Wrong number of arguments.');
    print(usage);
    io.exit(1);
  }
  var mode = args[0];
  if (!modes.contains(mode)) {
    print('Invalid mode: $mode');
    print(usage);
    io.exit(1);
  }
  var rootDir = io.Directory(args[1]);
  if (!rootDir.existsSync()) {
    print('rootDir does not exist: ${rootDir.path}');
    io.exit(1);
  }

  var dartFiles = <String, List<String>>{};
  var entities = rootDir.listSync(recursive: true, followLinks: false);
  for (var entity in entities) {
    if (entity.path.endsWith('.dart')) {
      var dartFileForwardSlashes = entity.path.replaceAll('\\', '/');
      var rootDirForwardSlashes = rootDir.path.replaceAll('\\', '/');
      var dartFile =
          dartFileForwardSlashes.replaceFirst(rootDirForwardSlashes + '/', '');
      dartFiles[dartFile] = [];

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
          if (io.File(rootDir.path + '/' + resolvedUri).existsSync()) {
            dartFiles[dartFile].add(resolvedUri);
          }
        }
      }
    }
  }

  var jsonText = getPrettyJSONString(dartFiles);
  // print(jsonText);

  switch (mode) {
    case 'dot':
      {
        var dotString = generateDotGraph(dartFiles);
        print(dotString);
        break;
      }
    case 'metrics':
      {
        print('Metrics not implemented yet.');
        break;
      }
  }
}
