class DigraphSimple {
  String id;
  String label;
  List<Node> nodes = [];
  List<Edge> edges = [];
  String rankdir;

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
}''');
  }
}

class Node {
  String id;
  String label;

  Node(this.id, this.label);

  @override
  String toString() {
    return '"$id" [label="$label"];';
  }
}

class Edge {
  String from;
  String to;
  bool dashed;

  Edge(this.from, this.to, {this.dashed = false});

  @override
  String toString() {
    return '"$from" -> "$to"${dashed ? ' [style=dashed]' : ''};';
  }
}

class DigraphWithSubgraphs {
  String id;
  String label;
  List<Subgraph> subgraphs = [];
  List<Edge> edges = [];
  String rankdir;

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
}''');
  }
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
