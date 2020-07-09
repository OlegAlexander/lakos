import 'dart:io' as io;
import 'dart:convert' as convert;
import 'package:path/path.dart' as path;
import 'package:lakos/model.dart' as model;
import 'package:lakos/resolve_imports.dart' as resolve_imports;
import 'package:lakos/metrics.dart' as metrics;

// TODO Do another pass on this function.
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
  var graph = model.Model('G', 'Dependency Graph');
  // Add nodes
  for (var file in dartFiles.keys) {
    graph.nodes.add(model.Node(file, path.basenameWithoutExtension(file)));
  }
  // Add edges
  for (var source in dartFiles.keys) {
    for (var target in dartFiles[source]) {
      graph.edges.add(model.Edge(source, target));
    }
  }
  return graph.toString();
}

String prettyJson(jsonObject) {
  return convert.JsonEncoder.withIndent('  ').convert(jsonObject);
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
      currentSubgraph.nodes.add(file.path
          .replaceFirst(rootDir.parent.path, '')
          .replaceAll('\\', '/'));
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

List<model.Node> getDartFiles(io.Directory rootDir, List<String> ignoreDirs) {
  var nodes = <model.Node>[];
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
      nodes.add(model.Node(
          file.path.replaceFirst(rootDir.parent.path, '').replaceAll('\\', '/'),
          path.basenameWithoutExtension(file.path)));
    }

    // Recurse breadth first
    dirs.addAll(dirsOnly);
  }

  return nodes;
}

List<model.Edge> getEdges(io.Directory rootDir) {
  var edges = <model.Edge>[];
  var entities = rootDir.listSync(recursive: true, followLinks: false);
  var dartFiles = entities
      .whereType<io.File>()
      .where((file) => file.path.endsWith('.dart'));

  var pubspecYaml = resolve_imports.findPubspecYaml(rootDir);

  for (var dartFile in dartFiles) {
    var from = dartFile.path
        .replaceFirst(rootDir.parent.path, '')
        .replaceAll('\\', '/');

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
              .replaceFirst(rootDir.parent.path, '')
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

String getOutput(model.Model graph, String format) {
  var output = '';
  switch (format) {
    case 'dot':
      output = graph.toString();
      break;
    case 'json':
      output = prettyJson(graph.toJson());
      break;
  }
  return output;
}

// TODO Make this function return an exit code instead of a string.
// TODO Add --metrics and --no-metrics option.
String lakos(io.Directory rootDir, String format, io.File output,
    List<String> ignoreDirs, bool tree, String layout) {
  if (!rootDir.isAbsolute) {
    rootDir = io.Directory(path.normalize(rootDir.absolute.path));
  }
  if (!rootDir.existsSync()) {
    print('Dir does not exist: ${rootDir.path}');
    // TODO Return error or throw exception instead of exit?
    io.exit(1);
  }

  var graph = model.Model('G', '', rankdir: layout)
    ..rootDir = rootDir.path.replaceAll('\\', '/')
    ..nodes = getDartFiles(rootDir, ignoreDirs);
  if (tree) {
    graph.subgraphs = getDirTree(rootDir, ignoreDirs);
  }
  graph.edges.addAll(getEdges(rootDir));
  graph.metrics = metrics.computeAllMetrics(graph);
  return getOutput(graph, format);
}
