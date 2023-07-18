/**
 * @id xss-sources
 * @name XSS sources
 * @kind problem
 */

import javascript
import semmle.javascript.security.dataflow.DomBasedXssQuery
import models.UI5AMDModule

from DataFlow::Configuration cfg, DataFlow::Node source
where cfg.isSource(source, _)
select source, source.toString()
