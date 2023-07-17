/**
 * @id xss-summary
 * @name XSS summary
 * @kind problem
 */

import javascript
import queries.Ui5XssConfiguration

from Ui5XssConfiguration cfg, DataFlow::Node start, DataFlow::Node end
where cfg.isAdditionalFlowStep(start, end, _, _)
select start, end
