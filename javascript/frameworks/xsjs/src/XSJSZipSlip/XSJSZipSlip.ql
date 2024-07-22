/**
 * @name XSJS Zip Slip
 * @description Saving an entry of a zip archive into a file with its stated path
 *              allows for a path traversal and writing to an arbitrary location.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 7.5
 * @precision medium
 * @id js/xsjs-zip-slip
 * @tags security
 */

import javascript
import advanced_security.javascript.frameworks.xsjs.XSJSZipSlipQuery
import DataFlow::PathGraph

from Configuration config, DataFlow::PathNode source, DataFlow::PathNode sink
where config.hasFlowPath(source, sink)
select sink, source, sink, "The path of $@ being saved depends on a $@.", sink, "this zip file", source, "user-provided value"
