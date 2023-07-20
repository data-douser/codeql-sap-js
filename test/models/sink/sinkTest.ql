/**
 * @id xss-sinks
 * @name XSS sinks
 * @kind problem
 */

import javascript
import queries.UI5XssConfiguration

from DataFlow::Configuration cfg, DataFlow::Node sink
where cfg.isSink(sink, _)
select getUI5SinkLocation(sink), sink.toString()
