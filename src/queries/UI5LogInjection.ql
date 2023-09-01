/**
 * @name Log injection
 * @description Building log entries from user-controlled sources is vulnerable to
 *              insertion of forged log entries by a malicious user.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 7.8
 * @precision medium
 * @id js/ui5-log-injection
 * @tags security
 *       external/cwe/cwe-117
 */

import javascript
import models.UI5DataFlowShared
import models.UI5DataFlowShared::UI5PathGraph
import semmle.javascript.security.dataflow.LogInjectionQuery as LogInjection

class UI5LogInjectionConfiguration extends LogInjection::LogInjectionConfiguration {
  override predicate isAdditionalFlowStep(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    super.isAdditionalFlowStep(start, end, inLabel, outLabel)
    or
    UI5DataFlow::isAdditionalFlowStep(start, end, inLabel, outLabel)
  }
}

/**
 * An remote source associated with a `UI5BoundNode`
 */
class UI5ModelSource extends UI5DataFlow::UI5ModelSource, LogInjection::Source { }

/**
 * A log-injection sink associated with a `UI5BoundNode`
 */
class UI5ModelSink extends UI5DataFlow::UI5ModelSink, LogInjection::Sink { }

from
  UI5LogInjectionConfiguration cfg, UI5PathGraph::UI5PathNode source,
  UI5PathGraph::UI5PathNode sink, UI5PathGraph::UI5PathNode primarySource,
  UI5PathGraph::UI5PathNode primarySink
where
  cfg.hasFlowPath(source.asDataFlowPathNode(), sink.asDataFlowPathNode()) and
  primarySource = source.getAPrimarySource() and
  primarySink = sink.getAPrimarySink()
select primarySink, primarySource, primarySink, "Log entry depends on a $@.", primarySource,
  "user-provided value"
