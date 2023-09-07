/**
 * @id path-sinks
 * @name Path injection sinks
 * @kind problem
 * @problem.severity error
 */

import javascript
import models.UI5DataFlow
import semmle.javascript.security.dataflow.TaintedPathQuery as TaintedPathQuery

class UI5ExtLogISink extends TaintedPathQuery::Sink {
    UI5ExtLogISink() { this = ModelOutput::getASinkNode("ui5-path-injection").asSink() }
  }

from TaintedPathQuery::Sink sink
select sink, sink.toString()
