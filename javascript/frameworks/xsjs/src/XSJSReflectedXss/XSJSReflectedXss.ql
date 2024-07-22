/**
 * @name XSJS Reflected XSS
 * @description Including uncontrolled value into a response body and setting it to
 *              a scriptable MIME type allows for cross-site scripting vulnerability.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 7.8
 * @precision medium
 * @id js/xsjs-reflected-xss
 * @tags security
 */

import javascript
import advanced_security.javascript.frameworks.xsjs.XSJSReflectedXssQuery
import DataFlow::PathGraph

from Configuration config, DataFlow::PathNode source, DataFlow::PathNode sink
where config.hasFlowPath(source, sink)
select sink, source, sink, "Reflected XSS vulnerability due to $@.", source, "user-provided value"
