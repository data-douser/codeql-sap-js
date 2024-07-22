/**
 * @name XSJS SQL injection
 * @description Directly concatenating an uncontrolled value with an SQL query allows
 *              for an SQL injection vulnerability.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 8.8
 * @precision medium
 * @id js/xsjs-sql-injection
 * @tags security
 */

import javascript
import advanced_security.javascript.frameworks.xsjs.XSJSSqlInjectionQuery
import DataFlow::PathGraph

from Configuration config, DataFlow::PathNode source, DataFlow::PathNode sink
where config.hasFlowPath(source, sink)
select sink, source, sink, "This query depends on a $@.", source, "user-provided value"
