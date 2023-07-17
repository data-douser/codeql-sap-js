/**
 * @name Client-side cross-site scripting
 * @id Ui5Xss
 * @kind path-problem
 */

import javascript
import DataFlow::PathGraph
import Ui5XssConfiguration

from Ui5XssConfiguration cfg, DataFlow::SourcePathNode source, DataFlow::SinkPathNode sink
where cfg.hasFlowPath(source, sink)
select getSinkLocation(sink), source, sink, "XSS vulnerability due to $@.",
  getSourceLocation(source), "user-provided value"
