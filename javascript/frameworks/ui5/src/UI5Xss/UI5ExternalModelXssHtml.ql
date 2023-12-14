/**
 * @name UI5 Client-side cross-site scripting
 * @description Writing server-side model data directly to a UI5 View
 *              allows for a cross-site scripting vulnerability.
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
import advanced_security.javascript.frameworks.ui5.UI5DataFlow::UI5PathGraph
import advanced_security.javascript.frameworks.ui5.UI5XssQuery

/*
 * Goal:
 * 1. Alert on the HTML Control
 * 2. Mark the remote flow source as source
 * 3. Maintain zero-step path (hence one path showing up from source to itself)
 */

from Configuration config, UI5PathGraph::UI5PathNode source, UI5PathGraph::UI5PathNode sink
where
  config.hasFlowPath(source.getPathNode(), sink.getPathNode()) and
  config.isSource(source.asDataFlowNode()) and
  config.isSink(sink.asDataFlowNode()) and
  isUI5Sink(sink)
select sink.getAPrimaryHtmlISink(), source, sink, "nooooo"
