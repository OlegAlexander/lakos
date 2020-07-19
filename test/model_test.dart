import 'package:test/test.dart';
import 'package:lakos/model.dart';
import 'dart:convert';

String prettyJson(jsonObject) {
  return JsonEncoder.withIndent('  ').convert(jsonObject);
}

void main() {
  test('Digraph simple', () {
    var g = Model();
    g.nodes['a'] = Node('a', 'a');
    g.nodes['b'] = Node('b', 'b');
    g.nodes['c'] = Node('c', 'c');
    g.edges.add(Edge('a', 'b'));
    g.edges.add(Edge('a', 'c', directive: Directive.Export));
    print(g);
    expect(g.toString(), '''
digraph "" {
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
    g = Model(rankdir: 'LR');
    g.nodes['a'] = Node('a', 'a');
    g.nodes['b'] = Node('b', 'b');
    g.nodes['c'] = Node('c', 'c');
    g.edges.add(Edge('a', 'b'));
    g.edges.add(Edge('a', 'c', directive: Directive.Export));
    print(g);
    expect(g.toString(), '''
digraph "" {
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
    expect(prettyJson(g), '''
{
  "rootDir": ".",
  "nodes": {
    "a": {
      "id": "a",
      "label": "a",
      "cd": null
    },
    "b": {
      "id": "b",
      "label": "b",
      "cd": null
    },
    "c": {
      "id": "c",
      "label": "c",
      "cd": null
    }
  },
  "subgraphs": [],
  "edges": [
    {
      "from": "a",
      "to": "b",
      "directive": "import"
    },
    {
      "from": "a",
      "to": "c",
      "directive": "export"
    }
  ],
  "metrics": null
}''');
  });

  test('Subgraph simple', () {
    var g = Model();
    var c0 = Subgraph('zero', 'zero');
    c0.nodes.add('a');
    c0.nodes.add('b');
    c0.nodes.add('c');
    g.subgraphs.add(c0);
    g.edges.add(Edge('a', 'b'));
    g.edges.add(Edge('a', 'c'));
    print(g);
    expect(g.toString(), '''
digraph "" {
  style=rounded;
  rankdir=TB;
  subgraph "cluster~zero" {
    label="zero";
    "a";
    "b";
    "c";
  }
  "a" -> "b";
  "a" -> "c";
}
''');

    // rankdirLR
    g = Model(rankdir: 'LR');
    c0 = Subgraph('zero', 'zero');
    c0.nodes.add('a');
    c0.nodes.add('b');
    c0.nodes.add('c');
    g.subgraphs.add(c0);
    g.edges.add(Edge('a', 'b'));
    g.edges.add(Edge('a', 'c'));
    print(g);
    expect(g.toString(), '''
digraph "" {
  style=rounded;
  rankdir=LR;
  subgraph "cluster~zero" {
    label="zero";
    "a";
    "b";
    "c";
  }
  "a" -> "b";
  "a" -> "c";
}
''');
  });

  test('Subgraph nested', () {
    var g = Model();
    var c0 = Subgraph('zero', 'zero');
    c0.nodes.add('a');
    c0.nodes.add('b');
    var c1 = Subgraph('one', 'one');
    c1.nodes.add('c');
    c0.subgraphs.add(c1);
    g.subgraphs.add(c0);
    g.edges.add(Edge('a', 'b'));
    g.edges.add(Edge('a', 'c'));
    print(g);
    expect(g.toString(), '''
digraph "" {
  style=rounded;
  rankdir=TB;
  subgraph "cluster~zero" {
    label="zero";
    "a";
    "b";
    subgraph "cluster~one" {
      label="one";
      "c";
    }
  }
  "a" -> "b";
  "a" -> "c";
}
''');

    print(prettyJson(g));
    expect(prettyJson(g), '''
{
  "rootDir": ".",
  "nodes": {},
  "subgraphs": [
    {
      "id": "zero",
      "label": "zero",
      "nodes": [
        "a",
        "b"
      ],
      "subgraphs": [
        {
          "id": "one",
          "label": "one",
          "nodes": [
            "c"
          ],
          "subgraphs": []
        }
      ]
    }
  ],
  "edges": [
    {
      "from": "a",
      "to": "b",
      "directive": "import"
    },
    {
      "from": "a",
      "to": "c",
      "directive": "import"
    }
  ],
  "metrics": null
}''');
  });

  test('Node', () {
    var node = Node('a', 'a');
    print(node);
    expect(node.toString(), '"a" [label="a"];');
    print(jsonEncode(node));
    expect(jsonEncode(node), '{"id":"a","label":"a","cd":null}');
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
    var metrics = Metrics(true, 10, 40, 12.3, 2.5, 1.2);
    print(metrics);
    expect(metrics.toString(),
        '"metrics" [label=" isAcyclic: true \\l numNodes: 10 \\l ccd: 40 \\l acd: 12.3 \\l acdp: 2.5% \\l nccd: 1.2 \\l", shape=rect];');
    print(jsonEncode(metrics));
    expect(jsonEncode(metrics),
        '{"isAcyclic":true,"numNodes":10,"ccd":40,"acd":12.3,"acdp":2.5,"nccd":1.2}');
  });
}
