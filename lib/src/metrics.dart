import 'dart:math';
import 'dart:io';
import 'package:lakos/src/model.dart';
import 'package:directed_graph/directed_graph.dart';

const precision = 2;

/// Compute the component dependency of each node.
/// The component dependency (CD) is the number of nodes a particular node depends on
/// directly or transitively, including itself.
void computeNodeCDs(DirectedGraph<String> graph, Model model) {
  for (var v in graph.vertices) {
    model.nodes[v.data].cd = 0;
  }
  for (var v in graph.vertices) {
    var nodes = [v];
    var visited = <String>{};
    while (nodes.isNotEmpty) {
      var next = nodes.removeAt(0);
      // Only visit each node once
      if (!visited.contains(next.data)) {
        model.nodes[v.data].cd += 1;
        visited.add(next.data);
        nodes.addAll(graph.edges(next));
      }
    }
  }
}

/// Compute node inDegree, outDegree, isOrphan, and instability.
/// inDegree is the number of nodes that depend on this node.
/// outDegree is the number of nodes this node depends on.
/// Instability is a node metric by Robert C. Martin related to the Stable-Dependencies Principle:
/// Depend in the direction of stability.
/// Instability = outDegree / (inDegree + outDegree)
/// In general, node instability should decrease in the direction of dependency.
/// In other words, lower level nodes should be more stable and more reusable than higher level nodes.
void computeNodeDegreeMetrics(DirectedGraph<String> graph, Model model) {
  for (var v in graph.vertices) {
    model.nodes[v.data].inDegree = graph.inDegree(v);
    model.nodes[v.data].outDegree = graph.outDegree(v);
    if (model.nodes[v.data].inDegree + model.nodes[v.data].outDegree > 0) {
      model.nodes[v.data].instability = (model.nodes[v.data].outDegree /
              (model.nodes[v.data].inDegree + model.nodes[v.data].outDegree))
          .toPrecision(precision);
    }
  }
}

/// Return the cumulative component dependency, which is the sum of all component dependencies.
/// The CCD can be interpreted as the total "coupling" of the graph.
/// Lower is better.
int computeCCD(Model model) {
  var ccd = 0;
  for (var node in model.nodes.values) {
    ccd += node.cd;
  }
  return ccd;
}

/// A node that has inDegree and outDegree of 0 is an orphan.
List<String> computeOrphans(Model model) {
  var orphans = <String>[];
  for (var node in model.nodes.values) {
    if (node.inDegree == 0 && node.outDegree == 0) {
      orphans.add(node.id);
    }
  }
  return orphans;
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

/// Return the number of lines of code ignoring comments and blank lines.
/// This is a naive SLOC counter. It doesn't deal correctly with
/// comments inside multi-line strings
/// or multi-line comments in the middle of code.
int countSloc(File dartFile) {
  var lines = dartFile.readAsLinesSync();
  var sloc = 0;
  var multilineComment = false;
  for (var line in lines) {
    line = line.trim();
    if (line.startsWith('//')) {
      continue;
    }
    if (line == '') {
      continue;
    }
    if (line.startsWith('/*')) {
      multilineComment = true;
      continue;
    }
    if (multilineComment) {
      if (line.endsWith('*/')) {
        multilineComment = false;
      }
      continue;
    }
    sloc += 1;
  }
  return sloc;
}

void computeNodeSlocs(Model model) {
  for (var node in model.nodes.values) {
    try {
      node.sloc = countSloc(File('${model.rootDir}${node.id}'));
    } catch (e) {
      node.sloc = null;
    }
  }
}

int computeTotalSloc(Model model) {
  var total = 0;
  for (var node in model.nodes.values) {
    if (node.sloc != null) {
      total += node.sloc;
    }
  }
  return total;
}

/// Round to precision.
/// Source: https://stackoverflow.com/a/32205216
extension NumberRounding on num {
  num toPrecision(int precision) {
    return num.parse((this).toStringAsFixed(precision));
  }
}

Metrics computeAllMetrics(Model model) {
  var digraph = model.toDirectedGraph();
  computeNodeCDs(digraph, model);
  computeNodeDegreeMetrics(digraph, model);
  computeNodeSlocs(model);
  var ccd = computeCCD(model);
  var orphans = computeOrphans(model);
  var numNodes = digraph.vertices.length;
  var totalSloc = computeTotalSloc(model);
  var avgSloc = totalSloc / numNodes;
  var firstCycle = digraph.cycle.map((node) => node.data).toList();
  var metrics = Metrics(
      firstCycle.isEmpty,
      firstCycle,
      numNodes,
      orphans,
      ccd,
      computeACD(ccd, numNodes).toPrecision(precision),
      computeACDP(ccd, numNodes).toPrecision(precision),
      computeNCCD(ccd, numNodes).toPrecision(precision),
      totalSloc,
      avgSloc.toPrecision(precision));
  return metrics;
}
