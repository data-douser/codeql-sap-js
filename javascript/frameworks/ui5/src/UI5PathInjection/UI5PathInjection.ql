/**
 * @name UI5 Path Injection
 * @description Constructing path from an uncontrolled remote source to be passed
 *              to a filesystem API allows for manipulation of the local filesystem.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 7.8
 * @precision medium
 * @id js/ui5-path-injection
 * @tags security
 *       external/cwe/cwe-022
 *       external/cwe/cwe-035
 */

import javascript
import advanced_security.javascript.frameworks.ui5.dataflow.DataFlow
import advanced_security.javascript.frameworks.ui5.dataflow.DataFlow::UI5PathGraph
import semmle.javascript.security.dataflow.TaintedPathQuery as TaintedPathQuery

class UI5PathInjectionConfiguration extends TaintedPathQuery::Configuration {
  override predicate isSource(DataFlow::Node node) { node instanceof RemoteFlowSource }

  override predicate isSink(DataFlow::Node node) {
    node = ModelOutput::getASinkNode("ui5-path-injection").asSink()
  }
}

from
  UI5PathInjectionConfiguration config, UI5PathNode source, UI5PathNode sink,
  UI5PathNode primarySource
where
  config.hasFlowPath(source.getPathNode(), sink.getPathNode()) and
  primarySource = source.getAPrimarySource()
select sink, primarySource, sink, "Path of a saved file depends on a $@.", primarySource,
  "user-provided value"
