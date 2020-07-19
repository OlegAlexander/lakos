import 'package:lakos/model.dart' as m;
import 'package:directed_graph/directed_graph.dart' as dg;
import 'dart:math';

/// Convert model to digraph.
dg.DirectedGraph<String> convertModelToDigraph(m.Model model) {
  var edgeMap = <String, List<String>>{};

  // Add nodes
  for (var node in model.nodes.values) {
    if (!edgeMap.containsKey(node.id)) {
      edgeMap[node.id] = [];
    }
  }

  // Add edges
  for (var edge in model.edges) {
    edgeMap[edge.from].add(edge.to);
  }

  // Make vertexMap from edgeMap
  var vertexMap = <String, dg.Vertex<String>>{};
  for (var k in edgeMap.keys) {
    vertexMap[k] = dg.Vertex(k);
  }

  // Make vertexEdgeMap from edgeMap and vertexMap
  var vertexEdgeMap = <dg.Vertex<String>, List<dg.Vertex<String>>>{};
  for (var k in edgeMap.keys) {
    vertexEdgeMap[vertexMap[k]] = edgeMap[k].map((x) => vertexMap[x]).toList();
  }

  return dg.DirectedGraph<String>(vertexEdgeMap);
}

/// Return a map of component dependencies.
/// The component dependency (CD) is the number of nodes a particular node depends on
/// directly or transitively, including itself.
Map<String, int> computeCDMap(dg.DirectedGraph<String> graph) {
  var cdMap = <String, int>{};
  for (var v in graph.vertices) {
    cdMap[v.data] = 0;
  }
  for (var v in graph.vertices) {
    var nodes = [v];
    var visited = <String>{};
    while (nodes.isNotEmpty) {
      var next = nodes.removeAt(0);
      // Only visit each node once
      if (!visited.contains(next.data)) {
        cdMap[v.data] += 1;
        visited.add(next.data);
        nodes.addAll(graph.edges(next));
      }
    }
  }
  return cdMap;
}

/// Return the cumulative component dependency, which is the sum of all component dependencies.
/// The CCD can be interpreted as the total "coupling" of the graph.
/// Lower is better.
int computeCCD(Map<String, int> cdMap) {
  var sumOfAllCDs = cdMap.values.fold(0, (prev, curr) => prev + curr);
  return sumOfAllCDs;
}

/// Return the average component dependency.
/// ACD = CCD / numNodes
/// It can be interpreted as the average number of nodes that will need to change when one node changes.
/// Lower is better.
double computeACD(int ccd, int numNodes) => ccd / numNodes;

/// Return the average component dependency as a percentage of numNodes.
/// ACDP = (ACD / numNodes) * 100 = (CCD / numNodes^2) * 100
/// It can be interpreted as the average percentage of nodes that will need to change when one node changes.
/// As a general trend, every new node added should reduce the ACDP.
/// This metric is my original research. Use at your own risk.
/// Lower is better.
double computeACDP(int ccd, int numNodes) =>
    (ccd / (numNodes * numNodes)) * 100;

/// Base 2 log.
double log2(num x) => log(x) / ln2;

/// The CCD of a balanced binary tree of size n.
double binaryTreeCCD(int n) => (n + 1) * log2(n + 1) - n;

/// Return the normalized cumulative component dependency.
/// This is the CCD divided by a CCD of a binary tree of the same size.
/// If the NCCD is below 1.0, the graph is "horizontal".
/// If the NCCD is above 1.0, the graph is "vertical".
/// If the NCCD is above 2.0, the graph probably contains cycles.
/// Lower is better.
double computeNCCD(int ccd, int numNodes) => ccd / binaryTreeCCD(numNodes);

/// Round to precision.
/// Source: https://stackoverflow.com/a/32205216
extension NumberRounding on num {
  num toPrecision(int precision) {
    return num.parse((this).toStringAsFixed(precision));
  }
}

m.Metrics computeAllMetrics(m.Model model) {
  var digraph = convertModelToDigraph(model);
  var cdMap = computeCDMap(digraph);
  var ccd = computeCCD(cdMap);
  var numNodes = digraph.vertices.length;
  var metrics = m.Metrics(
      digraph.isAcyclic(),
      numNodes,
      ccd,
      computeACD(ccd, numNodes).toPrecision(2),
      computeACDP(ccd, numNodes).toPrecision(2),
      computeNCCD(ccd, numNodes).toPrecision(2));
  return metrics;
}
