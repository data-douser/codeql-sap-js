/**
 * @id log-sinks
 * @name Log injection sinks
 * @kind problem
 */

import javascript
import models.UI5AMDModule
import semmle.javascript.security.dataflow.LogInjectionQuery

from LogInjectionConfiguration config, DataFlow::Node sink
where config.isSink(sink, _)
select sink, sink.toString()
