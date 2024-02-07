/**
 * @id formula-injection-sinks
 * @name Formula injection sinks
 * @kind problem
 * @problem.severity error
 */

import javascript
import advanced_security.javascript.frameworks.ui5.UI5FormulaInjectionQuery
import advanced_security.javascript.frameworks.ui5.dataflow.DataFlow as UI5DataFlow

from UI5FormulaInjectionConfiguration config, DataFlow::Node sink
where config.isSink(sink)
select sink, sink.toString()
