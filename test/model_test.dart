import 'package:test/test.dart';
import 'package:lakos/model.dart';
import 'dart:convert';

String prettyJson(jsonObject) {
  return JsonEncoder.withIndent('  ').convert(jsonObject);
}

void main() {
  test('Digraph simple', () {
    var g = Digraph('G', 'Digraph simple');
    g.nodes.add(Node('a', 'a'));
    g.nodes.add(Node('b', 'b'));
    g.nodes.add(Node('c', 'c'));
    g.edges.add(Edge('a', 'b'));
    g.edges.add(Edge('a', 'c', directive: Directive.Export));
    print(g);
    expect(g.toString(), '''
digraph "G" {
  label="Digraph simple";
  labelloc=top;
  style=rounded;
  rankdir=TB;
  "a" [label="a"];
  "b" [label="b"];
  "c" [label="c"];
  "a" -> "b";
  "a" -> "c" [style=dashed];
}
''');

    // rankdir LR
    g = Digraph('G', 'Digraph simple', rankdir: 'LR');
    g.nodes.add(Node('a', 'a'));
    g.nodes.add(Node('b', 'b'));
    g.nodes.add(Node('c', 'c'));
    g.edges.add(Edge('a', 'b'));
    g.edges.add(Edge('a', 'c', directive: Directive.Export));
    print(g);
    expect(g.toString(), '''
digraph "G" {
  label="Digraph simple";
  labelloc=top;
  style=rounded;
  rankdir=LR;
  "a" [label="a"];
  "b" [label="b"];
  "c" [label="c"];
  "a" -> "b";
  "a" -> "c" [style=dashed];
}
''');

    print(prettyJson(g));
  });

  test('Subgraph simple', () {
    var g = Digraph('G', 'Subgraph simple');
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
  rankdir=TB;
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
    g = Digraph('G', 'Subgraph simple', rankdir: 'LR');
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
    var g = Digraph('G', 'Subgraph nested');
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
  rankdir=TB;
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

    print(prettyJson(g));
  });

  test('Node', () {
    var node = Node('a', 'a');
    print(node);
    expect(node.toString(), '"a" [label="a"];');
    print(jsonEncode(node));
    expect(jsonEncode(node), '{"id":"a","label":"a"}');
  });

  test('Edge', () {
    var edge = Edge('a', 'b');
    print(edge);
    expect(edge.toString(), '"a" -> "b";');
    edge = Edge('a', 'b', directive: Directive.Export);
    print(edge);
    expect(edge.toString(), '"a" -> "b" [style=dashed];');
    print(jsonEncode(edge));
    expect(jsonEncode(edge), '{"from":"a","to":"b","directive":"export"}');
  });

  test('Metrics', () {
    var metrics = Metrics(true, 40, 12.3, 1.2);
    print(metrics);
    expect(metrics.toString(),
        '"metrics" [label="isAcyclic: true \\l ccd: 40 \\l acd: 12.3 \\l nccd: 1.2 \\l", shape=rect];');
    print(jsonEncode(metrics));
    expect(jsonEncode(metrics),
        '{"isAcyclic":true,"ccd":40,"acd":12.3,"nccd":1.2}');
  });
}
