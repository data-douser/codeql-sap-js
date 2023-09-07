/**
 * @id log-sinks
 * @name Log injection sinks
 * @kind problem
 * @problem.severity error
 */

import javascript
import models.UI5AMDModule
import semmle.javascript.security.dataflow.LogInjectionQuery

from DataFlow::Node sink
where sink = ModelOutput::getASinkNode("log-injection").asSink()
select sink, "log-injection sink."
