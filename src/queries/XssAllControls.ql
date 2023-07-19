/**
 * @name Client-side cross-site scripting
 * @description Writing user input directly to a UI5 View allows for
 *              a cross-site scripting vulnerability.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 6.1
 * @precision high
 * @id js/ui5-xss
 * @tags security
 *       external/cwe/cwe-079
 *       external/cwe/cwe-116
 */

import javascript
import DataFlow::PathGraph
import UI5XssConfiguration

private Locatable getUI5SourceLocation(DataFlow::PathNode node) {
  result = node.getNode().(UI5ModelSource).getBindingPath() and
  result = any(UI5View view).getASource()
  or
  result = node.getNode().asExpr()
}

private Locatable getUI5SinkLocation(DataFlow::PathNode node) {
  result = node.getNode().(UI5ModelSink).getBindingPath() and
  result = any(UI5View view).getAnHtmlISink()
  or
  result = node.getNode().asExpr()
}

from UI5XssConfiguration cfg, DataFlow::PathNode source, DataFlow::PathNode sink
where cfg.hasFlowPath(source, sink)
select getUI5SinkLocation(sink), source, sink, "XSS vulnerability due to $@.",
  getUI5SourceLocation(source), "user-provided value"
