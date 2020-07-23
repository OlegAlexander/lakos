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
  // TODO Consider adding more fields like sloc, inDegree, outDegree, and isOrphan.
  // Maybe isOrphan can be rendered with a bold circle.
  String id;
  String label;
  int cd;
  bool showNodeMetrics;

  Node(this.id, this.label, {this.showNodeMetrics = false});

  @override
  String toString() {
    return '"$id" [label="$label${showNodeMetrics ? '\\ncd: $cd' : ''}"];';
  }

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'cd': cd};
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
  int numLevels;
  int ccd;
  double acd;
  double acdp;
  double nccd;
  // TODO Add avgSLOC with min and max thresholds.

  Metrics(
    this.isAcyclic,
    this.numNodes,
    this.ccd,
    this.acd,
    this.acdp,
    this.nccd,
  );

  @override
  String toString() {
    return '"metrics" [label=" isAcyclic: $isAcyclic \\l numNodes: $numNodes \\l ccd: $ccd \\l acd: $acd \\l acdp: $acdp% \\l nccd: $nccd \\l", shape=rect];';
  }

  Map<String, dynamic> toJson() => {
        'isAcyclic': isAcyclic,
        'numNodes': numNodes,
        'ccd': ccd,
        'acd': acd,
        'acdp': acdp,
        'nccd': nccd,
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
