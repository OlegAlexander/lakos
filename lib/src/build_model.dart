import 'dart:io' as io;
import 'package:path/path.dart' as path;
import 'package:glob/glob.dart' as glob;
import 'package:lakos/src/model.dart' as model;
import 'package:lakos/src/resolve_imports.dart' as resolve_imports;
import 'package:lakos/src/metrics.dart' as metrics;

const alwaysIgnore = '{.**,doc/**,build/**}';

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

List<model.Subgraph> getDirTree(io.Directory rootDir, String ignore) {
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

  var dartFilesGlob = glob.Glob('*.dart');
  var ignoreGlob =
      glob.Glob(ignore, context: path.Context(current: rootDir.path));
  var alwaysIgnoreGlob =
      glob.Glob(alwaysIgnore, context: path.Context(current: rootDir.path));

  // Recursively build the subgraph tree.
  // The trick is to keep track of two lists (dirs and subgraphs)
  // in the while loop at the same time.
  while (dirs.isNotEmpty) {
    var currentDir = dirs.removeAt(0);
    var currentSubgraph = subgraphs.removeAt(0);

    var dirsOnly = currentDir
        .listSync(recursive: false, followLinks: false)
        .whereType<io.Directory>()
        .where((dir) => !alwaysIgnoreGlob.matches(dir.path))
        .where((dir) => !ignoreGlob.matches(dir.path));
    var filesOnly = dartFilesGlob
        .listSync(root: currentDir.path, followLinks: false)
        .whereType<io.File>()
        .where((file) => !alwaysIgnoreGlob.matches(file.path))
        .where((file) => !ignoreGlob.matches(file.path));

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

Iterable<io.File> _getDartFiles(io.Directory rootDir, String ignore) {
  var dartFilesGlob = glob.Glob('**.dart');
  var ignoreGlob =
      glob.Glob(ignore, context: path.Context(current: rootDir.path));
  var alwaysIgnoreGlob =
      glob.Glob(alwaysIgnore, context: path.Context(current: rootDir.path));

  // TODO Filtering after the fact might be slow. Consider doing your own recursion using alwaysIgnoreGlob.
  var dartFiles = dartFilesGlob
      .listSync(root: rootDir.path, followLinks: false)
      .whereType<io.File>()
      .where((file) => !alwaysIgnoreGlob.matches(file.path))
      .where((file) => !ignoreGlob.matches(file.path));
  return dartFiles;
}

Map<String, model.Node> getDartFileNodes(
    io.Directory rootDir, String ignore, bool showNodeMetrics) {
  var dartFiles = _getDartFiles(rootDir, ignore);

  // Add dart files as nodes
  var nodes = <String, model.Node>{};
  for (var file in dartFiles) {
    var id = file.path.replaceFirst(rootDir.path, '').replaceAll('\\', '/');
    var label = path.basenameWithoutExtension(file.path);
    nodes[id] = model.Node(id, label, showNodeMetrics: showNodeMetrics);
  }
  return nodes;
}

List<model.Edge> getEdges(
    io.Directory rootDir, String ignore, io.File pubspecYaml) {
  var edges = <model.Edge>[];

  var dartFiles = _getDartFiles(rootDir, ignore);

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
/// Throws StringScannerException if ignoreGlob is invalid.
model.Model buildModel(io.Directory rootDir,
    {String ignoreGlob = '!**',
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

  var graph = model.Model(
      rootDir: rootDir.path.replaceAll('\\', '/'), rankdir: layout)
    ..nodes =
        getDartFileNodes(rootDir, ignoreGlob, showNodeMetrics && showMetrics);

  if (showTree) {
    graph.subgraphs = getDirTree(rootDir, ignoreGlob);
  }

  graph.edges.addAll(getEdges(rootDir, ignoreGlob, pubspecYaml));

  if (showMetrics) {
    graph.metrics = metrics.computeAllMetrics(graph);
  }

  return graph;
}
