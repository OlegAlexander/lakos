import 'dart:convert' as convert;

/// Main container class to hold the data model.
class Model {
  String rootDir;
  String rankdir;
  Map<String, Node> nodes = {};
  List<Subgraph> subgraphs = [];
  List<Edge> edges = [];
  Metrics metrics;

  Model({this.rootDir = '.', this.rankdir = 'TB'});

  @override
  String toString() {
    return _prettyPrintDot('''
digraph "" {
style=rounded;
rankdir=$rankdir;
${nodes.values.join('\n')}
${subgraphs.join('\n')}
${edges.join('\n')}
${metrics ?? ''}
}''');
  }

  Map<String, dynamic> toJson() => {
        'rootDir': rootDir,
        'nodes': nodes,
        'subgraphs': subgraphs,
        'edges': edges,
        'metrics': metrics
      };

  String getOutput(OutputFormat format) {
    switch (format) {
      case OutputFormat.Dot:
        return toString();
      case OutputFormat.Json:
        return _prettyJson(toJson());
    }
    return ''; // Will never reach here.
  }
}

enum OutputFormat { Dot, Json }

/// Dart libraries are represented as nodes in a directed graph.
class Node {
  String id;
  String label;
  int cd;
  int inDegree;
  int outDegree;
  double instability;
  int sloc;
  bool showNodeMetrics;

  Node(this.id, this.label, {this.showNodeMetrics = false});

  @override
  String toString() {
    return '"$id" [label="$label${showNodeMetrics ? ' \\n cd: $cd \\n inDegree: $inDegree \\n outDegree: $outDegree \\n instability: $instability \\n sloc: $sloc' : ''}"${inDegree == 0 && outDegree == 0 ? ', style=bold' : ''}];';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'cd': cd,
        'inDegree': inDegree,
        'outDegree': outDegree,
        'instability': instability,
        'sloc': sloc
      };
}

enum Directive { Import, Export }

/// Import/Export dependencies are represented as edges in the graph.
class Edge {
  String from;
  String to;
  Directive directive;

  Edge(this.from, this.to, {this.directive = Directive.Import});

  @override
  String toString() {
    return '"$from" -> "$to"${directive == Directive.Export ? ' [style=dashed]' : ''};';
  }

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'directive': directive.toString().split('.').last.toLowerCase()
      };
}

/// Subfolders are represented as subgraphs.
class Subgraph {
  String id;
  String label;
  List<String> nodes = [];
  List<Subgraph> subgraphs = [];
  Subgraph parent;

  Subgraph(this.id, this.label);

  @override
  String toString() {
    var wrappedNodes = nodes.map((x) => '"$x";');
    return '''
subgraph "cluster~$id" {
label="$label";
${wrappedNodes.join('\n')}
${subgraphs.join('\n')}
}''';
  }

  Map<String, dynamic> toJson() =>
      {'id': id, 'label': label, 'nodes': nodes, 'subgraphs': subgraphs};
}

/// Store global metrics here.
class Metrics {
  bool isAcyclic;
  int numNodes;
  List<String> orphans = [];
  int ccd;
  double acd;
  double acdp;
  double nccd;
  int totalSloc;
  double avgSloc;
  // TODO Maybe add min, max, median, and standard deviation sloc?

  Metrics(this.isAcyclic, this.numNodes, this.orphans, this.ccd, this.acd,
      this.acdp, this.nccd, this.totalSloc, this.avgSloc);

  @override
  String toString() {
    return '"metrics" [label=" isAcyclic: $isAcyclic \\l numNodes: $numNodes \\l numOrphans: ${orphans.length} \\l ccd: $ccd \\l acd: $acd \\l acdp: $acdp% \\l nccd: $nccd \\l totalSloc: $totalSloc \\l avgSloc: $avgSloc \\l", shape=rect];';
  }

  Map<String, dynamic> toJson() => {
        'isAcyclic': isAcyclic,
        'numNodes': numNodes,
        'orphans': orphans,
        'ccd': ccd,
        'acd': acd,
        'acdp': acdp,
        'nccd': nccd,
        'totalSloc': totalSloc,
        'avgSloc': avgSloc
      };
}

String _prettyJson(jsonObject, {String indent = '  '}) {
  return convert.JsonEncoder.withIndent(indent).convert(jsonObject);
}

String _trimLines(String dot) {
  return dot.split('\n').map((line) => line.trim()).join('\n');
}

/// Properly indent dot string.
String _prettyPrintDot(String dot, {String indent = '  '}) {
  var level = 0;
  var newTokens = <String>[];
  for (var token in _trimLines(dot).split('')) {
    switch (token) {
      case '\n':
        continue;
      case ';':
        newTokens.add(';\n');
        for (var i = 0; i < level; i++) {
          newTokens.add(indent);
        }
        break;
      case '{':
        newTokens.add('{\n');
        level++;
        for (var i = 0; i < level; i++) {
          newTokens.add(indent);
        }
        break;
      case '}':
        newTokens.removeLast(); // Unindent
        newTokens.add('}\n');
        level--;
        for (var i = 0; i < level; i++) {
          newTokens.add(indent);
        }
        break;
      default:
        newTokens.add(token);
    }
  }
  return newTokens.join('');
}
