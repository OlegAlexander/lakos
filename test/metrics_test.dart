import 'package:test/test.dart';
import 'package:lakos/src/model.dart';
import 'package:lakos/src/metrics.dart';

// TODO Add more tests/expects.
void main() {
  test('convertModelToDigraph', () {
    var g = Model();
    g.nodes['a'] = Node('a', 'a');
    g.nodes['b'] = Node('b', 'b');
    g.nodes['c'] = Node('c', 'c');
    g.nodes['d'] = Node('d', 'd');
    g.nodes['e'] = Node('e', 'e'); // Orphan
    g.edges.add(Edge('a', 'b'));
    g.edges.add(Edge('a', 'c'));
    g.edges.add(Edge('b', 'd'));
    g.edges.add(Edge('c', 'd'));
    // g.edges.add(Edge('d', 'a')); // Cycle
    print(g);
    var digraph = convertModelToDigraph(g);
    print(digraph);
    print(digraph.edgeMap);
    print(digraph.isAcyclic());
    print(digraph.localSources()); // Levels
    for (var v in digraph.vertices) {
      print('$v -> ${digraph.edges(v)}');
    }
  });

  test('computeCCD', () {
    var g = Model();
    g.nodes['a'] = Node('a', 'a');
    g.nodes['b'] = Node('b', 'b');
    g.nodes['c'] = Node('c', 'c');
    g.nodes['d'] = Node('d', 'd');
    g.nodes['e'] = Node('e', 'e'); // Orphan
    g.edges.add(Edge('a', 'b'));
    g.edges.add(Edge('a', 'c'));
    g.edges.add(Edge('b', 'd'));
    g.edges.add(Edge('c', 'd'));
    // g.edges.add(Edge('d', 'a')); // Cycle
    print(g);
    var digraph = convertModelToDigraph(g);
    print(digraph.edgeMap);
    print('isAcyclic: ${digraph.isAcyclic()}');
    print('levels: ${digraph.localSources()}');
    computeNodeCDs(digraph, g);
    var ccd = computeCCD(g);
    print('ccd: $ccd');
    print('acd: ${computeACD(ccd, digraph.vertices.length)}');
    print('acdp: ${computeACDP(ccd, digraph.vertices.length)}%');
    print('nccd: ${computeNCCD(ccd, digraph.vertices.length)}');
  });

  test('binaryTreeCCD', () {
    // From page 191 of LSC++SD
    expect(binaryTreeCCD(1), 1.0);
    expect(binaryTreeCCD(3), 5.0);
    expect(binaryTreeCCD(7), 17.0);
    expect(binaryTreeCCD(15), 49.0);
  });

  test('computeAllMetrics', () {
    var g = Model();
    g.nodes['a'] = Node('a', 'a');
    g.nodes['b'] = Node('b', 'b');
    g.nodes['c'] = Node('c', 'c');
    g.nodes['d'] = Node('d', 'd');
    // g.nodes['e'] = Node('e', 'e'); // Orphan
    g.edges.add(Edge('a', 'b'));
    g.edges.add(Edge('a', 'c'));
    g.edges.add(Edge('b', 'd'));
    g.edges.add(Edge('c', 'd'));
    // g.edges.add(Edge('d', 'a')); // Cycle
    print(g);
    var metrics = computeAllMetrics(g);
    print(metrics);
    print(metrics.toJson());
  });
}
