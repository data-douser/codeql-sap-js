/**
 * @id xss-sources
 * @name XSS sources
 * @kind problem
 */

import javascript
import queries.UI5XssConfiguration

from DataFlow::Configuration cfg, DataFlow::Node source, string sourceBindingPathStr
where cfg.isSource(source, _)
select getUI5SinkLocation(source, sourceBindingPathStr), source.toString()
