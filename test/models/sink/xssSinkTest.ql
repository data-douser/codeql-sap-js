/**
 * @id xss-sinks
 * @name XSS sinks
 * @kind problem
 * @problem.severity error
 */

import javascript
import models.UI5DataFlow
import semmle.javascript.security.dataflow.DomBasedXssQuery as DomBasedXss

class UI5ExtLogISink extends DomBasedXss::Sink {
  UI5ExtLogISink() { this = ModelOutput::getASinkNode("ui5-html-injection").asSink() }
}

from DomBasedXss::Sink sink
select sink, sink.toString()
