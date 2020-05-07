// dart lakos.dart "C:\Users\olega\Documents\Dart\linter" | dot -Tsvg -o linter.svg
// dart lakos.dart "C:\Users\olega\Documents\Dart\hauberk\lib\src\engine" | dot -Tpng -Gdpi=300 -o hauberk.png

import 'dart:io' as io;
import 'dart:convert' as convert;
import 'package:path/path.dart' as path;
import 'package:lakos/graphviz.dart' as gv;
import 'package:lakos/resolve_imports.dart' as resolve_imports;

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
  if (importPath.isEmpty) {
    return null;
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

gv.DigraphWithSubgraphs getDirTree(
    io.Directory rootDir, List<String> ignoreDirs) {
  var tree = gv.DigraphWithSubgraphs('G', '');
  var dirs = [rootDir];
  var subgraphs = [
    gv.Subgraph(
        rootDir.path
            .replaceFirst(rootDir.parent.path, '')
            .replaceAll('\\', '/'),
        path.basename(rootDir.path))
  ];
  tree.subgraphs.add(subgraphs.first);

  var leaves = <gv.Subgraph>[];

  // Recursively build the subgraph tree.
  // The trick is to keep track of two lists (dirs and subgraphs)
  // in the while loop at the same time.
  while (dirs.isNotEmpty) {
    var currentDir = dirs.removeAt(0);
    var currentSubgraph = subgraphs.removeAt(0);

    var currentDirItems =
        currentDir.listSync(recursive: false, followLinks: false);
    var dirsOnly = currentDirItems
        .whereType<io.Directory>()
        .where((dir) => !ignoreDirs.contains(path.basename(dir.path)));
    var filesOnly = currentDirItems
        .whereType<io.File>()
        .where((file) => file.path.endsWith('.dart'));

    if (dirsOnly.isEmpty) {
      leaves.add(currentSubgraph);
    }

    // Add directories as subgraphs
    for (var dir in dirsOnly) {
      var subgraph = gv.Subgraph(
          dir.path.replaceFirst(rootDir.parent.path, '').replaceAll('\\', '/'),
          path.basename(dir.path));
      currentSubgraph.subgraphs.add(subgraph);
      subgraph.parent = currentSubgraph;
    }

    // Add dart files as nodes
    for (var file in filesOnly) {
      currentSubgraph.nodes.add(gv.Node(
          file.path.replaceFirst(rootDir.parent.path, '').replaceAll('\\', '/'),
          path.basenameWithoutExtension(file.path)));
    }

    // Recurse breadth first
    dirs.addAll(dirsOnly);
    subgraphs.addAll(currentSubgraph.subgraphs);
  }

  // Recursively remove empty subgraphs which don't contain any dart files
  while (leaves.isNotEmpty) {
    var leaf = leaves.removeLast();
    if (leaf.parent != null) {
      if (leaf.nodes.isEmpty && leaf.subgraphs.isEmpty) {
        leaf.parent.subgraphs.remove(leaf);

        // Recurse up the tree depth first
        leaves.add(leaf.parent);
      }
    }
  }

  return tree;
}

List<gv.Edge> getEdges(io.Directory rootDir) {
  var edges = <gv.Edge>[];
  var entities = rootDir.listSync(recursive: true, followLinks: false);
  var dartFiles = entities
      .whereType<io.File>()
      .where((file) => file.path.endsWith('.dart'));

  var packageConfig = resolve_imports.findPackageConfigUriSync(rootDir);

  for (var dartFile in dartFiles) {
    var from = dartFile.path
        .replaceFirst(rootDir.parent.path, '')
        .replaceAll('\\', '/');

    // Grab the imports from the dart file
    var lines = dartFile.readAsLinesSync();
    for (var line in lines) {
      // TODO: Draw a dashed edge for export
      if (line.startsWith('import') || line.startsWith('export')) {
        var parsedImportLine = parseImportLine(line);
        if (parsedImportLine == null) {
          continue;
        }

        io.File resolvedFile;
        if (parsedImportLine.startsWith('package:')) {
          resolvedFile =
              resolve_imports.resolvePackage(packageConfig, parsedImportLine);
        } else if (parsedImportLine.startsWith('dart:')) {
          continue; // Ignore dart: imports
        } else {
          resolvedFile =
              resolve_imports.resolveFile(dartFile, parsedImportLine);
        }

        // Only add dart files that exist--account for imports inside strings, comments, etc.
        if (resolvedFile != null &&
            resolvedFile.existsSync() &&
            path.isWithin(rootDir.path, resolvedFile.path)) {
          edges.add(gv.Edge(
              from,
              resolvedFile.path
                  .replaceFirst(rootDir.parent.path, '')
                  .replaceAll('\\', '/')));
        }
      }
    }
  }
  return edges;
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
  if (!rootDir.isAbsolute) {
    rootDir = rootDir.absolute.parent;
  }
  if (!rootDir.existsSync()) {
    print('rootDir does not exist: ${rootDir.path}');
    io.exit(1);
  }

  var ignoreDirs = ['.git', '.svn', '.dart_tool', 'doc'];
  var tree = getDirTree(rootDir, ignoreDirs);
  tree.edges.addAll(getEdges(rootDir));

  switch (mode) {
    case 'dot':
      {
        print(tree);
        break;
      }
    case 'metrics':
      {
        print('Metrics not implemented yet.');
        break;
      }
  }
}
