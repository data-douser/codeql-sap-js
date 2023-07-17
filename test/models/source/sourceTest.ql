/**
 * @id xss-sources
 * @name XSS sources
 * @kind problem
 */

import javascript
import models.UI5AMDModule
import queries.Ui5XssConfiguration

from Configuration cfg, DataFlow::Node source
where cfg.isSource(source, _)
select source, source.toString()
