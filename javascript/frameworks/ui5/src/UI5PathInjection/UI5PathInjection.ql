/**
 * @name UI5 Path Injection
 * @description Passing data from a remote source to a local storage API leads to manipulating the client's filesystem.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 7.8
 * @precision medium
 * @id js/ui5-log-injection
 * @tags security
 *       external/cwe/cwe-829
 */

import javascript
import advanced_security.javascript.frameworks.ui5.dataflow.DataFlow
import advanced_security.javascript.frameworks.ui5.dataflow.DataFlow::UI5PathGraph
import semmle.javascript.security.dataflow.HttpToFileAccessQuery as HttpToFileAccess

class UI5PathInjectionConfiguration extends HttpToFileAccess::Configuration {
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
select sink, primarySource, sink, "Path or file content depends on a $@.", primarySource,
  "user-provided value"
