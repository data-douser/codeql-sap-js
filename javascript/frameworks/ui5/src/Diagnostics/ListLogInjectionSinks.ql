/**
 * @name SAP UI5 log injection sinks
 * @description List all SAP UI5 log injection sinks
 * @kind problem
 * @problem.severity info
 * @precision high
 * @id js/ui5-list-log-injection-sinks
 * @tags diagnostics
 */

import javascript

from DataFlow::Node sink, string kind
where
  sink = ModelOutput::getASinkNode(kind).asSink() and
  kind = "ui5-log-injection"
select sink, "SAP UI5 log injection sink with kind: " + kind
