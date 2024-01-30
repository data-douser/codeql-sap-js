/**
 * @name UI5 Formula Injection
 * @description Saving data from an uncontrolled remote source using filesystem or local storage
 *              leads to disclosure of sensitive information or forgery of entry.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 7.8
 * @precision medium
 * @id js/ui5-formula-injection
 * @tags security
 *       external/cwe/cwe-1236
 */

import javascript
import advanced_security.javascript.frameworks.ui5.dataflow.DataFlow
import advanced_security.javascript.frameworks.ui5.dataflow.DataFlow::UI5PathGraph

class UI5FormulaInjectionConfiguration extends TaintTracking::Configuration {
  UI5FormulaInjectionConfiguration() { this = "UI5 Formula Injection" }

  override predicate isSource(DataFlow::Node node) { node instanceof RemoteFlowSource }

  override predicate isSink(DataFlow::Node node) {
    node = ModelOutput::getASinkNode("ui5-formula-injection").asSink()
  }
}

from
  UI5FormulaInjectionConfiguration config, UI5PathNode source, UI5PathNode sink,
  UI5PathNode primarySource
where
  config.hasFlowPath(source.getPathNode(), sink.getPathNode()) and
  primarySource = source.getAPrimarySource()
select sink, primarySource, sink, "The content of a saved file depends on a $@.", primarySource,
  "user-provided value"
