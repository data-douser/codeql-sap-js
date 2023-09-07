/**
 * @id xss-sources
 * @name XSS sources
 * @kind problem
 * @problem.severity error
 */

import javascript
import models.UI5DataFlow
import semmle.javascript.security.dataflow.DomBasedXssQuery as DomBasedXss

from DomBasedXss::Source source
select source, source.toString()
