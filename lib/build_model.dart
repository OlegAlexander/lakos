import 'dart:io' as io;
import 'package:path/path.dart' as path;
import 'package:lakos/model.dart' as model;
import 'package:lakos/resolve_imports.dart' as resolve_imports;
import 'package:lakos/metrics.dart' as metrics;

// TODO Do another pass on this function.
// TODO Maybe move this function and similar functionality, like sloc counting, to a parse library.
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

List<model.Subgraph> getDirTree(io.Directory rootDir, List<String> ignoreDirs) {
  var dirs = [rootDir];
  var subgraphs = [
    model.Subgraph(
        rootDir.path
            .replaceFirst(rootDir.parent.path, '')
            .replaceAll('\\', '/'),
        path.basename(rootDir.path))
  ];
  var treeSubgraphs = <model.Subgraph>[];
  treeSubgraphs.add(subgraphs.first);

  var leaves = <model.Subgraph>[];

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
      var subgraph = model.Subgraph(
          dir.path.replaceFirst(rootDir.parent.path, '').replaceAll('\\', '/'),
          path.basename(dir.path));
      currentSubgraph.subgraphs.add(subgraph);
      subgraph.parent = currentSubgraph;
    }

    // Add dart files as nodes
    for (var file in filesOnly) {
      currentSubgraph.nodes
          .add(file.path.replaceFirst(rootDir.path, '').replaceAll('\\', '/'));
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

  return treeSubgraphs;
}

Map<String, model.Node> getDartFiles(
    io.Directory rootDir, List<String> ignoreDirs, bool showNodeMetrics) {
  var nodes = <String, model.Node>{};
  var dirs = [rootDir];

  while (dirs.isNotEmpty) {
    var currentDir = dirs.removeAt(0);

    var currentDirItems =
        currentDir.listSync(recursive: false, followLinks: false);
    var dirsOnly = currentDirItems
        .whereType<io.Directory>()
        .where((dir) => !ignoreDirs.contains(path.basename(dir.path)));
    var filesOnly = currentDirItems
        .whereType<io.File>()
        .where((file) => file.path.endsWith('.dart'));

    // Add dart files as nodes
    for (var file in filesOnly) {
      var id = file.path.replaceFirst(rootDir.path, '').replaceAll('\\', '/');
      var label = path.basenameWithoutExtension(file.path);
      nodes[id] = model.Node(id, label, showNodeMetrics: showNodeMetrics);
    }

    // Recurse breadth first
    dirs.addAll(dirsOnly);
  }

  return nodes;
}

List<model.Edge> getEdges(io.Directory rootDir, io.File pubspecYaml) {
  var edges = <model.Edge>[];
  var entities = rootDir.listSync(recursive: true, followLinks: false);
  var dartFiles = entities
      .whereType<io.File>()
      .where((file) => file.path.endsWith('.dart'));

  for (var dartFile in dartFiles) {
    var from =
        dartFile.path.replaceFirst(rootDir.path, '').replaceAll('\\', '/');

    // Grab the imports from the dart file
    var lines = dartFile.readAsLinesSync();
    for (var line in lines) {
      if (line.startsWith('import') || line.startsWith('export')) {
        var parsedImportLine = parseImportLine(line);
        if (parsedImportLine == null) {
          continue;
        }

        io.File resolvedFile;
        if (parsedImportLine.startsWith('package:')) {
          resolvedFile = resolve_imports.resolvePackageFileFromPubspecYaml(
              pubspecYaml, parsedImportLine);
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
          var to = resolvedFile.path
              .replaceFirst(rootDir.path, '')
              .replaceAll('\\', '/');
          // No self loops
          if (from != to) {
            edges.add(model.Edge(from, to,
                directive: line.startsWith('import')
                    ? model.Directive.Import
                    : model.Directive.Export));
          }
        }
      }
    }
  }
  return edges;
}

class PubspecYamlNotFoundException implements Exception {
  final String message;
  PubspecYamlNotFoundException(this.message);
  @override
  String toString() => 'PubspecYamlNotFoundException: $message';
}

/// This is the main function for API usage.
/// Returns the Model object.
/// Throws FileSystemException if rootDir doesn't exist.
/// Throws PubspecYamlNotFoundException if pubspec.yaml can't be found in or above the rootDir.
// TODO Consider exporting this function and Metrics in lib and hiding everything underneath in lib/src.
model.Model buildModel(io.Directory rootDir,
    {List<String> ignoreDirs = const ['.git', '.dart_tool'],
    bool showTree = true,
    bool showMetrics = true,
    bool showNodeMetrics = false,
    String layout = 'TB'}) {
  // Convert relative to absolute path.
  if (!rootDir.isAbsolute) {
    rootDir = io.Directory(path.normalize(rootDir.absolute.path));
  }

  var pubspecYaml = resolve_imports.findPubspecYaml(rootDir);
  if (pubspecYaml == null) {
    throw PubspecYamlNotFoundException(
        'pubspec.yaml not found in or above the root directory.');
  }

  var graph =
      model.Model(rootDir: rootDir.path.replaceAll('\\', '/'), rankdir: layout)
        ..nodes =
            getDartFiles(rootDir, ignoreDirs, showNodeMetrics && showMetrics);
  if (showTree) {
    graph.subgraphs = getDirTree(rootDir, ignoreDirs);
  }
  graph.edges.addAll(getEdges(rootDir, pubspecYaml));
  if (showMetrics) {
    graph.metrics = metrics.computeAllMetrics(graph);
  }

  return graph;
}
