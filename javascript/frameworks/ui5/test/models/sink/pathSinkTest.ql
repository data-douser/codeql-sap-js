/**
 * @id path-sinks
 * @name Path injection sinks
 * @kind problem
 * @problem.severity error
 */

import javascript
import semmle.javascript.security.dataflow.TaintedPathQuery as TaintedPathQuery
import advanced_security.javascript.frameworks.ui5.dataflow.DataFlow as UI5DataFlow // HACK: Why does this test pass only when we import this?

class UI5ExtPathISink extends TaintedPathQuery::Sink {
  UI5ExtPathISink() { this = ModelOutput::getASinkNode("ui5-path-injection").asSink() }
}

from TaintedPathQuery::Sink sink
select sink, sink.toString()
