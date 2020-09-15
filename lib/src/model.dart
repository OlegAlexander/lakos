import 'dart:convert';
import 'package:directed_graph/directed_graph.dart';

/// The main container class to hold the data model.
/// Returned from the [buildModel] function.
class Model {
  /// All node id paths are relative to the root directory.
  String rootDir;

  /// Stores the graph layout direction.
  /// Possible values: TB, BT, LR, and RL.
  String rankdir;

  /// Any X11 or hex color.
  String nodeColor;

  /// A map of nodes (Dart files).
  Map<String, Node> nodes = {};

  /// A list of subgraphs which represent subfolders.
  List<Subgraph> subgraphs = [];

  /// Imports and exports are represented as edges in a directed graph.
  List<Edge> edges = [];

  /// Stores global metrics.
  Metrics metrics;

  /// This constructor is not meant to be used directly.
  /// Use the [buildModel] function instead.
  Model({this.rootDir = '.', this.rankdir = 'TB', this.nodeColor = 'lavender'});

  /// Returns this object in dot format.
  @override
  String toString() {
    return _prettyPrintDot('''
digraph "" {
style=rounded;
node [style=filled fillcolor="$nodeColor"];
rankdir=$rankdir;
${nodes.values.join('\n')}
${subgraphs.join('\n')}
${edges.join('\n')}
${metrics ?? ''}
}''');
  }

  /// Returns this object in JSON format.
  Map<String, dynamic> toJson() => {
        'rootDir': rootDir,
        'nodes': nodes,
        'subgraphs': subgraphs,
        'edges': edges,
        'metrics': metrics
      };

  /// Returns the string representation of the model depending on the [OutputFormat].
  String getOutput(OutputFormat format) {
    switch (format) {
      case OutputFormat.Dot:
        return toString();
      case OutputFormat.Json:
        return _prettyJson(toJson());
    }
    return ''; // Will never reach here.
  }

  /// Converts a Model to a [DirectedGraph] from the `directed_graph` library.
  /// May be useful for further analysis of the dependency graph.
  DirectedGraph<String> toDirectedGraph() {
    var edgeMap = <String, List<String>>{};

    // Add nodes
    for (var node in nodes.values) {
      if (!edgeMap.containsKey(node.id)) {
        edgeMap[node.id] = [];
      }
    }

    // Add edges
    for (var edge in edges) {
      edgeMap[edge.from].add(edge.to);
    }

    return DirectedGraph<String>.fromData(edgeMap);
  }
}

/// Used in [Model.getOutput].
enum OutputFormat { Dot, Json }

/// Dart files are represented as nodes in a directed graph.
/// See the README for more details about each node metric.
class Node {
  /// The file path relative to [Model.rootDir].
  String id;

  /// The filename without extension.
  String label;

  /// Component Dependency.
  int cd;

  /// Number of incoming edges.
  int inDegree;

  /// Number of outgoing edges.
  int outDegree;

  /// Robert C. Martin's Instability metric.
  double instability;

  /// Source Lines of Code.
  int sloc;

  /// Whether to display node metrics or not.
  bool showNodeMetrics;

  /// Constructor.
  Node(this.id, this.label, {this.showNodeMetrics = false});

  /// Returns this object in dot format.
  @override
  String toString() {
    return '"$id" [label="$label${showNodeMetrics ? ' \\n cd: $cd \\n inDegree: $inDegree \\n outDegree: $outDegree \\n instability: $instability \\n sloc: $sloc' : ''}"${inDegree == 0 && outDegree == 0 ? ' shape=octagon' : ''}];';
  }

  /// Returns this object in JSON format.
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

/// Import/Export directive used in [Edge].
enum Directive { Import, Export }

/// Import/Export dependencies are represented as edges in a directed graph.
class Edge {
  /// The source [Node.id].
  String from;

  /// The target [Node.id].
  String to;

  /// Import or Export.
  Directive directive;

  /// Constructor.
  Edge(this.from, this.to, {this.directive = Directive.Import});

  /// Returns this object in dot format.
  @override
  String toString() {
    return '"$from" -> "$to"${directive == Directive.Export ? ' [style=dashed]' : ''};';
  }

  /// Returns this object in JSON format.
  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'directive': directive.toString().split('.').last.toLowerCase()
      };
}

/// Subfolders are represented as subgraphs.
class Subgraph {
  /// The folder path relative to [Model.rootDir].
  String id;

  /// The folder name.
  String label;

  /// A list of node ids in this folder.
  List<String> nodes = [];

  /// A list of subfolders.
  List<Subgraph> subgraphs = [];

  /// The parent folder.
  Subgraph parent;

  /// Constructor.
  Subgraph(this.id, this.label);

  /// Returns this object in dot format.
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

  /// Returns this object in JSON format.
  Map<String, dynamic> toJson() =>
      {'id': id, 'label': label, 'nodes': nodes, 'subgraphs': subgraphs};
}

/// Stores global metrics.
/// See the README for more details about each metric.
class Metrics {
  /// Is this a directed acyclic graph (DAG)?
  bool isAcyclic;

  /// The first dependency cycle found if the graph is not acyclic.
  List<String> firstCycle = [];

  /// Number of nodes (dart files).
  int numNodes;

  /// Number of edges (dependencies).
  int numEdges;

  /// Average degree of a directed graph = numEdges/numNodes.
  double avgDegree;

  /// List of orphan nodes.
  List<String> orphans = [];

  /// Cumulative Component Dependency.
  int ccd;

  /// Average Component Dependency.
  double acd;

  /// Normalized Cumulative Component Dependency.
  double nccd;

  /// Total Source Lines of Code for all nodes.
  int totalSloc;

  /// Average Source Lines of Code per node.
  double avgSloc;

  /// Constructor.
  Metrics(
      this.isAcyclic,
      this.firstCycle,
      this.numNodes,
      this.numEdges,
      this.avgDegree,
      this.orphans,
      this.ccd,
      this.acd,
      this.nccd,
      this.totalSloc,
      this.avgSloc);

  /// Returns this object in dot format.
  @override
  String toString() {
    return '"metrics" [label=" isAcyclic: $isAcyclic \\l numNodes: $numNodes  \\l numEdges: $numEdges  \\l avgDegree: $avgDegree \\l numOrphans: ${orphans.length} \\l ccd: $ccd \\l acd: $acd \\l nccd: $nccd \\l totalSloc: $totalSloc \\l avgSloc: $avgSloc \\l" shape=rect];';
  }

  /// Returns this object in JSON format.
  Map<String, dynamic> toJson() => {
        'isAcyclic': isAcyclic,
        'firstCycle': firstCycle,
        'numNodes': numNodes,
        'numEdges': numEdges,
        'avgDegree': avgDegree,
        'orphans': orphans,
        'ccd': ccd,
        'acd': acd,
        'nccd': nccd,
        'totalSloc': totalSloc,
        'avgSloc': avgSloc
      };
}

String _prettyJson(jsonObject, {String indent = '  '}) {
  return JsonEncoder.withIndent(indent).convert(jsonObject);
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
