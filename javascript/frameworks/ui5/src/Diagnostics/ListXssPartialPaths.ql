/**
 * @name UI5 Client-side cross-site scripting partial paths
 * @description Lists all the partial paths from a remote source to a possible XSS sink taking UI5 specifiic steps and sanitizer into consideration.
 * @kind path-problem
 * @problem.severity info
 * @precision high
 * @id js/ui5-xss-partial-paths
 * @tags diagnostics
 */

import javascript
import advanced_security.javascript.frameworks.ui5.UI5XssQuery as UI5Xss
import DataFlow::PathGraph

class Configuration extends UI5Xss::Configuration {
  // Override these predicates to mimic the behavior of ForwardExploration.qll
  // We can't use ForwardExploration.qll directly because our configuration extends an existing configuration
  override predicate isSink(DataFlow::Node node) { any() }

  override predicate isSink(DataFlow::Node node, DataFlow::FlowLabel lbl) { any() }

  override predicate hasFlowPath(DataFlow::SourcePathNode source, DataFlow::SinkPathNode sink) {
    exists(DataFlow::MidPathNode last |
      source.getConfiguration() = this and
      source.getASuccessor*() = last and
      not last.getASuccessor() instanceof DataFlow::MidPathNode and
      last.getASuccessor() = sink
    )
  }
}

from Configuration cfg, DataFlow::PathNode source, DataFlow::PathNode node
where cfg.hasFlowPath(source, node)
select node, source, node, "Partial XSS path from $@ to $@", source, "source", node, "node"
