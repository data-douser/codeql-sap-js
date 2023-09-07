/**
 * @id log-sinks
 * @name Path injection sinks
 * @kind problem
 * @problem.severity error
 */

import javascript
import models.UI5DataFlow
import semmle.javascript.security.dataflow.TaintedPathQuery as TaintedPathQuery

from TaintedPathQuery::Sink sink
select sink, sink.toString()
