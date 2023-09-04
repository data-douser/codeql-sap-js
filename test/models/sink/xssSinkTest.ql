/**
 * @id xss-sinks
 * @name XSS sinks
 * @kind problem
 * @problem.severity error
 */

import javascript
import models.UI5DataFlowShared
import semmle.javascript.security.dataflow.DomBasedXssQuery as DomBasedXss

from DomBasedXss::Sink sink
select sink, sink.toString()
