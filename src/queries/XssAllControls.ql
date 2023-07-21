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

from
  UI5XssConfiguration cfg, DataFlow::PathNode source, DataFlow::PathNode sink,
  string srcBindingPathStr, string sinkBindingPathStr
where cfg.hasFlowPath(source, sink)
select getUI5SinkLocation(sink.getNode(), sinkBindingPathStr), source, sink,
  "XSS vulnerability due to $@ on $@ flowing to $@.",
  getUI5SourceLocation(source.getNode(), srcBindingPathStr), "user-provided value",
  srcBindingPathStr, srcBindingPathStr, getUI5SinkLocation(sink.getNode(), sinkBindingPathStr),
  sinkBindingPathStr