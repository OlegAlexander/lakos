import 'package:test/test.dart';
import 'package:lakos/src/model.dart';
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
    g.edges.add(Edge('a', 'c', directive: Directive.export));
    print(g);
    expect(g.toString(), '''
digraph "" {
  graph [style=rounded fontname="Arial Black" fontsize=13 penwidth=2.6];
  node [shape=rect style="filled,rounded" fontname=Arial fontsize=15 fillcolor=Lavender penwidth=1.3];
  edge [penwidth=1.3];
  "a" [label="a"];
  "b" [label="b"];
  "c" [label="c"];
  "a" -> "b";
  "a" -> "c" [style=dashed];
}
''');

    // rankdir LR
    g = Model();
    g.nodes['a'] = Node('a', 'a');
    g.nodes['b'] = Node('b', 'b');
    g.nodes['c'] = Node('c', 'c');
    g.edges.add(Edge('a', 'b'));
    g.edges.add(Edge('a', 'c', directive: Directive.export));
    print(g);
    expect(g.toString(), '''
digraph "" {
  graph [style=rounded fontname="Arial Black" fontsize=13 penwidth=2.6];
  node [shape=rect style="filled,rounded" fontname=Arial fontsize=15 fillcolor=Lavender penwidth=1.3];
  edge [penwidth=1.3];
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
      "cd": null,
      "inDegree": null,
      "outDegree": null,
      "instability": null,
      "sloc": null
    },
    "b": {
      "id": "b",
      "label": "b",
      "cd": null,
      "inDegree": null,
      "outDegree": null,
      "instability": null,
      "sloc": null
    },
    "c": {
      "id": "c",
      "label": "c",
      "cd": null,
      "inDegree": null,
      "outDegree": null,
      "instability": null,
      "sloc": null
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
  graph [style=rounded fontname="Arial Black" fontsize=13 penwidth=2.6];
  node [shape=rect style="filled,rounded" fontname=Arial fontsize=15 fillcolor=Lavender penwidth=1.3];
  edge [penwidth=1.3];
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
    g = Model();
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
  graph [style=rounded fontname="Arial Black" fontsize=13 penwidth=2.6];
  node [shape=rect style="filled,rounded" fontname=Arial fontsize=15 fillcolor=Lavender penwidth=1.3];
  edge [penwidth=1.3];
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
  graph [style=rounded fontname="Arial Black" fontsize=13 penwidth=2.6];
  node [shape=rect style="filled,rounded" fontname=Arial fontsize=15 fillcolor=Lavender penwidth=1.3];
  edge [penwidth=1.3];
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
    expect(jsonEncode(node),
        '{"id":"a","label":"a","cd":null,"inDegree":null,"outDegree":null,"instability":null,"sloc":null}');

    node = Node('a', 'a', showNodeMetrics: true);
    print(node);
    expect(node.toString(),
        '"a" [label="a \\n cd: null \\n inDegree: null \\n outDegree: null \\n instability: null \\n sloc: null"];');

    // Orphan
    node = Node('a', 'a');
    node.inDegree = 0;
    node.outDegree = 0;
    print(node);
    expect(node.toString(), '"a" [label="a" shape=octagon];');
  });

  test('Edge', () {
    var edge = Edge('a', 'b');
    print(edge);
    expect(edge.toString(), '"a" -> "b";');
    edge = Edge('a', 'b', directive: Directive.export);
    print(edge);
    expect(edge.toString(), '"a" -> "b" [style=dashed];');
    print(jsonEncode(edge));
    expect(jsonEncode(edge), '{"from":"a","to":"b","directive":"export"}');
  });

  test('Metrics', () {
    var metrics =
        Metrics(true, [], 10, 12, 1.1, [], 40, 12.3, 1.2, 1000, 250.0);
    print(metrics);
    expect(metrics.toString(),
        '"metrics" [label=" isAcyclic: true \\l numNodes: 10  \\l numEdges: 12  \\l avgDegree: 1.1 \\l numOrphans: 0 \\l ccd: 40 \\l acd: 12.3 \\l nccd: 1.2 \\l totalSloc: 1000 \\l avgSloc: 250.0 \\l"];');
    print(jsonEncode(metrics));
    expect(jsonEncode(metrics),
        '{"isAcyclic":true,"firstCycle":[],"numNodes":10,"numEdges":12,"avgDegree":1.1,"orphans":[],"ccd":40,"acd":12.3,"nccd":1.2,"totalSloc":1000,"avgSloc":250.0}');
  });
}
