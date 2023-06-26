import javascript
import semmle.javascript.security.dataflow.DomBasedXssQuery
import models.UI5AMDModule

from DataFlow::Configuration cfg, DataFlow::Node sink
where cfg.isSink(sink, _)
select sink
