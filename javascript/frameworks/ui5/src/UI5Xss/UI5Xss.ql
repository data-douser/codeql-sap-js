/**
 * @name UI5 Client-side cross-site scripting
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
import advanced_security.javascript.frameworks.ui5.dataflow.DataFlow as UI5DataFlow
import UI5DataFlow::UI5PathGraph
import advanced_security.javascript.frameworks.ui5.UI5XssQuery

from
  Configuration config, UI5PathGraph::UI5PathNode source, UI5PathGraph::UI5PathNode sink,
   UI5PathGraph::UI5PathNode primarySink
where
  config.hasFlowPath(source.getPathNode(), sink.getPathNode()) and
  config.isSource(source.asDataFlowNode()) and
  config.isSink(sink.asDataFlowNode()) and
  primarySink = sink.getAPrimaryHtmlISink()
select primarySink, source, primarySink, "XSS vulnerability due to $@.", source,
  "user-provided value"
