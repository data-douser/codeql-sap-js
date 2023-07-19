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
import Ui5XssConfiguration

from Ui5XssConfiguration cfg, DataFlow::SourcePathNode source, DataFlow::SinkPathNode sink
where cfg.hasFlowPath(source, sink)
select getUI5SinkLocation(sink), source, sink, "XSS vulnerability due to $@.",
  getUI5SourceLocation(source), "user-provided value"
