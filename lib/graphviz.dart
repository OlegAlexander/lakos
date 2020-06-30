class DigraphSimple {
  String id;
  String label;
  List<Node> nodes = [];
  List<Edge> edges = [];
  String rankdir;
  Metrics metrics;

  DigraphSimple(this.id, this.label, {this.rankdir = 'TB'});

  @override
  String toString() {
    return prettyPrintDot('''
digraph "$id" {
label="$label";
labelloc=top;
rankdir=$rankdir;
${nodes.join('\n')}
${edges.join('\n')}
${metrics ?? ''}
}''');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'rankdir': rankdir,
        'nodes': nodes,
        'edges': edges,
        'metrics': metrics
      };
}

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

class DigraphWithSubgraphs {
  String id;
  String label;
  List<Subgraph> subgraphs = [];
  List<Edge> edges = [];
  String rankdir;
  Metrics metrics;

  DigraphWithSubgraphs(this.id, this.label, {this.rankdir = 'TB'});

  @override
  String toString() {
    return prettyPrintDot('''
digraph "$id" {
label="$label";
labelloc=top;
style=rounded;
rankdir=$rankdir;
${subgraphs.join('\n')}
${edges.join('\n')}
${metrics ?? ''}
}''');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'rankdir': rankdir,
        'subgraphs': subgraphs,
        'edges': edges,
        'metrics': metrics
      };
}

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
