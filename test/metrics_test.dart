import 'package:test/test.dart';
import 'package:lakos/model.dart';
import 'package:lakos/metrics.dart';

// TODO Add more tests/expects.
void main() {
  test('convertModelToDigraph', () {
    var g = Model('G', 'Digraph simple');
    g.nodes.add(Node('a', 'a'));
    g.nodes.add(Node('b', 'b'));
    g.nodes.add(Node('c', 'c'));
    g.nodes.add(Node('d', 'd'));
    g.nodes.add(Node('e', 'e')); // Orphan
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
    var g = Model('G', 'Digraph simple');
    g.nodes.add(Node('a', 'a'));
    g.nodes.add(Node('b', 'b'));
    g.nodes.add(Node('c', 'c'));
    g.nodes.add(Node('d', 'd'));
    g.nodes.add(Node('e', 'e')); // Orphan
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
    var icdMap = computeICDMap(digraph);
    print('icdMap: $icdMap');
    var ccd = computeCCD(icdMap);
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
    var g = Model('G', 'Digraph simple');
    g.nodes.add(Node('a', 'a'));
    g.nodes.add(Node('b', 'b'));
    g.nodes.add(Node('c', 'c'));
    g.nodes.add(Node('d', 'd'));
    // g.nodes.add(Node('e', 'e')); // Orphan
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
