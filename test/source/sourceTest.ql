import javascript
import semmle.javascript.security.dataflow.DomBasedXssQuery
import UI5AMDModule

from DataFlow::Configuration cfg, DataFlow::Node source
where cfg.isSource(source, _)
select source
