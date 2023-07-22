/**
 * @id xss-sources
 * @name XSS sources
 * @kind problem
 */

import javascript
import queries.UI5XssConfiguration

from UI5XssConfiguration cfg, DataFlow::Node source
where cfg.isSource(source, _)
select getUI5SourceLocation(source), source.toString()
