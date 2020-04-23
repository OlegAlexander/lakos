class DigraphSimple {
  String id;
  String label;
  List<Node> nodes = [];
  List<Edge> edges = [];

  DigraphSimple(this.id, this.label);

  @override
  String toString() {
    return '''
digraph "$id" {
label="$label"; labelloc=top;
${nodes.join('\n')}
${edges.join('\n')}
}''';
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

  Edge(this.from, this.to);

  @override
  String toString() {
    return '"$from" -> "$to";';
  }
}

class DigraphWithSubgraphs {
  String id;
  String label;
  List<Subgraph> subgraphs = [];
  List<Edge> edges = [];

  DigraphWithSubgraphs(this.id, this.label);

  @override
  String toString() {
    return '''
digraph "$id" {
label="$label"; labelloc=top;
${subgraphs.join('\n')}
${edges.join('\n')}
}''';
  }
}

class Subgraph {
  String id;
  String label;
  List<Node> nodes = [];
  List<Subgraph> subgraphs = [];

  Subgraph(this.id, this.label);

  @override
  String toString() {
    return '''
subgraph "cluster~$id" {
label="$label"; labelloc=top;
${nodes.join('\n')}
${subgraphs.join('\n')}}''';
  }
}
