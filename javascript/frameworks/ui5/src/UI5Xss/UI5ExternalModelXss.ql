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
 * Goal: Find a path from UI5ExternalModel `booking_nobatch` to `writeAttribute` in CommentTextArea.js
 */

from Configuration config, UI5PathGraph::UI5PathNode source, UI5PathGraph::UI5PathNode sink
where
  config.hasFlowPath(source.asDataFlowPathNode(), sink.asDataFlowPathNode()) and
  config.isSource(source.asDataFlowPathNode().getNode()) and
  config.isSink(sink.asDataFlowPathNode().getNode())
select sink, source, sink, "nooooo"
