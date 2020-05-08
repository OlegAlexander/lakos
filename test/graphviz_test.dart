import 'package:test/test.dart';
import 'package:lakos/graphviz.dart';

void main() {
  test('Digraph simple', () {
    var g = DigraphSimple('G', 'Digraph simple');
    g.nodes.add(Node('a', 'a'));
    g.nodes.add(Node('b', 'b'));
    g.nodes.add(Node('c', 'c'));
    g.edges.add(Edge('a', 'b'));
    g.edges.add(Edge('a', 'c', dashed: true));
    print(g);
    expect(g.toString(), '''
digraph "G" {
  label="Digraph simple";
  labelloc=top;
  "a" [label="a"];
  "b" [label="b"];
  "c" [label="c"];
  "a" -> "b";
  "a" -> "c" [style=dashed];
}
''');

    // rankdirLR
    g = DigraphSimple('G', 'Digraph simple', rankdirLR: true);
    g.nodes.add(Node('a', 'a'));
    g.nodes.add(Node('b', 'b'));
    g.nodes.add(Node('c', 'c'));
    g.edges.add(Edge('a', 'b'));
    g.edges.add(Edge('a', 'c', dashed: true));
    print(g);
    expect(g.toString(), '''
digraph "G" {
  label="Digraph simple";
  labelloc=top;
  rankdir=LR;
  "a" [label="a"];
  "b" [label="b"];
  "c" [label="c"];
  "a" -> "b";
  "a" -> "c" [style=dashed];
}
''');
  });

  test('Subgraph simple', () {
    var g = DigraphWithSubgraphs('G', 'Subgraph simple');
    var c0 = Subgraph('zero', 'zero');
    c0.nodes.add(Node('a', 'a'));
    c0.nodes.add(Node('b', 'b'));
    c0.nodes.add(Node('c', 'c'));
    g.subgraphs.add(c0);
    g.edges.add(Edge('a', 'b'));
    g.edges.add(Edge('a', 'c'));
    print(g);
    expect(g.toString(), '''
digraph "G" {
  label="Subgraph simple";
  labelloc=top;
  style=rounded;
  subgraph "cluster~zero" {
    label="zero";
    "a" [label="a"];
    "b" [label="b"];
    "c" [label="c"];
  }
  "a" -> "b";
  "a" -> "c";
}
''');

    // rankdirLR
    g = DigraphWithSubgraphs('G', 'Subgraph simple', rankdirLR: true);
    c0 = Subgraph('zero', 'zero');
    c0.nodes.add(Node('a', 'a'));
    c0.nodes.add(Node('b', 'b'));
    c0.nodes.add(Node('c', 'c'));
    g.subgraphs.add(c0);
    g.edges.add(Edge('a', 'b'));
    g.edges.add(Edge('a', 'c'));
    print(g);
    expect(g.toString(), '''
digraph "G" {
  label="Subgraph simple";
  labelloc=top;
  style=rounded;
  rankdir=LR;
  subgraph "cluster~zero" {
    label="zero";
    "a" [label="a"];
    "b" [label="b"];
    "c" [label="c"];
  }
  "a" -> "b";
  "a" -> "c";
}
''');
  });

  test('Subgraph nested', () {
    var g = DigraphWithSubgraphs('G', 'Subgraph nested');
    var c0 = Subgraph('zero', 'zero');
    c0.nodes.add(Node('a', 'a'));
    c0.nodes.add(Node('b', 'b'));
    var c1 = Subgraph('one', 'one');
    c1.nodes.add(Node('c', 'c'));
    c0.subgraphs.add(c1);
    g.subgraphs.add(c0);
    g.edges.add(Edge('a', 'b'));
    g.edges.add(Edge('a', 'c'));
    print(g);
    expect(g.toString(), '''
digraph "G" {
  label="Subgraph nested";
  labelloc=top;
  style=rounded;
  subgraph "cluster~zero" {
    label="zero";
    "a" [label="a"];
    "b" [label="b"];
    subgraph "cluster~one" {
      label="one";
      "c" [label="c"];
    }
  }
  "a" -> "b";
  "a" -> "c";
}
''');
  });
}
