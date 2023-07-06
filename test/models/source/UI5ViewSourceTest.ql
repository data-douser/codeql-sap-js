/**
 * @id xss-ui5view-sources
 * @name XSS UI5View sources
 * @kind problem
 */

import javascript
import semmle.javascript.security.dataflow.DomBasedXssQuery
import models.UI5View

from UI5BindingPath bp
where bp = any(UI5View ui5v).getASource()
select bp, bp.toString() + " is a user input source."
