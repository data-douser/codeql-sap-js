/**
 * @id xss-summary
 * @name XSS summary
 * @kind problem
 */

import javascript
import semmle.javascript.security.dataflow.DomBasedXssQuery
import models.UI5AMDModule

from DataFlow::Configuration cfg, DataFlow::Node source, DataFlow::Node sink
where cfg.hasFlow(source, sink)
select source, source.toString(), sink, sink.toString()
