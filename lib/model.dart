/// Main container class to hold the data model.
class Digraph {
  String id;
  String label;
  String rankdir;
  List<Node> nodes = [];
  List<Subgraph> subgraphs = [];
  List<Edge> edges = [];
  Metrics metrics;

  Digraph(this.id, this.label, {this.rankdir = 'TB'});

  @override
  String toString() {
    return prettyPrintDot('''
digraph "$id" {
label="$label";
labelloc=top;
style=rounded;
rankdir=$rankdir;
${nodes.join('\n')}
${subgraphs.join('\n')}
${edges.join('\n')}
${metrics ?? ''}
}''');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'rankdir': rankdir,
        'nodes': nodes,
        'subgraphs': subgraphs,
        'edges': edges,
        'metrics': metrics
      };
}

/// Dart libraries are represented as nodes in a directed graph.
class Node {
  String id;
  String label;

  Node(this.id, this.label);

  @override
  String toString() {
    return '"$id" [label="$label"];';
  }

  Map<String, dynamic> toJson() => {'id': id, 'label': label};
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
  List<Node> nodes = [];
  List<Subgraph> subgraphs = [];
  Subgraph parent;

  Subgraph(this.id, this.label);

  @override
  String toString() {
    return '''
subgraph "cluster~$id" {
label="$label";
${nodes.join('\n')}
${subgraphs.join('\n')}
}''';
  }

  Map<String, dynamic> toJson() =>
      {'id': id, 'label': label, 'nodes': nodes, 'subgraphs': subgraphs};
}

/// Store global metrics here.
class Metrics {
  bool isAcyclic;
  int ccd;
  double acd;
  double nccd;

  Metrics(
    this.isAcyclic,
    this.ccd,
    this.acd,
    this.nccd,
  );

  @override
  String toString() {
    return '"metrics" [label="isAcyclic: $isAcyclic \\l ccd: $ccd \\l acd: $acd \\l nccd: $nccd \\l", shape=rect];';
  }

  Map<String, dynamic> toJson() => {
        'isAcyclic': isAcyclic,
        'ccd': ccd,
        'acd': acd,
        'nccd': nccd,
      };
}

String _trimLines(String dot) {
  return dot.split('\n').map((line) => line.trim()).join('\n');
}

/// Properly indent dot string.
String prettyPrintDot(String dot, {String indent = '  '}) {
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
