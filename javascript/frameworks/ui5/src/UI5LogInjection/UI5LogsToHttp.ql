/**
 * @name UI5 Log injection in outbound network request
 * @description Building log entries from user-controlled sources is vulnerable to
 *              insertion of forged log entries by a malicious user.
 * @kind path-problem
 * @problem.severity warning
 * @security-severity 6.5
 * @precision medium
 * @id js/ui5-log-injection-to-http
 * @tags security
 *       external/cwe/cwe-117
 */

import javascript
import advanced_security.javascript.frameworks.ui5.dataflow.DataFlow
import semmle.javascript.frameworks.data.internal.ApiGraphModels
import advanced_security.javascript.frameworks.ui5.dataflow.DataFlow::UI5PathGraph
import advanced_security.javascript.frameworks.ui5.UI5LogInjectionQuery
import semmle.javascript.security.dataflow.LogInjectionQuery as LogInjection

class ClientRequestInjectionVector extends DataFlow::Node {
  ClientRequestInjectionVector() {
    exists(ClientRequest req |
      this = req.getUrl() or
      this = req.getADataNode()
    )
  }
}

class UI5Logger extends RequiredObject {
  UI5Logger() { this.getDependency() = "sap/base/Log" }

  DataFlow::Node getALogListener() {
    exists(MethodCallNode addLogListenerCall |
      addLogListenerCall.getCalleeName() = "addLogListener" and
      result = addLogListenerCall.getArgument(0)
    )
  }

  MethodCallNode getLogEntriesCall() {
    result.getReceiver().getALocalSource() = this.asSourceNode() and
    result.getMethodName() = "getLogEntries"
  }
}

private predicate test(MethodCallNode call, Node receiver, SourceNode receiverSource) {
  call.getMethodName() = "getLogEntries" and
  receiver = call.getReceiver() and
  receiverSource = receiver.getALocalSource()
}

class SapLogger extends DataFlow::Node {
  SapLogger() { this = ModelOutput::getATypeNode("SapLogger").getInducingNode() }
}

class SapLogEntries extends SourceNode {
  SapLogEntries() { this = ModelOutput::getATypeNode("SapLogEntries").asSource() }
}

SourceNode isLogListener(TypeBackTracker t) {
  t.start() and
  exists(UI5Logger log | result = log.getALogListener())
  or
  exists(DataFlow::TypeBackTracker t2 | result = isLogListener(t2).backtrack(t2, t))
}

SourceNode isLogListener() { result = isLogListener(TypeBackTracker::end()) }

class LogListener extends DataFlow::Node {
  LogListener() { this = isLogListener() }

  FunctionNode getOnLogEntryMethod() {
    exists(DataFlow::PropWrite propWrite | propWrite.getPropertyName() = "onLogEntry" |
      result = propWrite.getRhs()
    )
  }
}

class UI5LogEntryToHttp extends TaintTracking::Configuration {
  UI5LogEntryToHttp() { this = "UI5 log entries being passed to outbound HTTP requests" }

  override predicate isSource(DataFlow::Node node, DataFlow::FlowLabel label) {
    node instanceof RemoteFlowSource and
    label = "not-logged"
  }

  /*
   * !!!!!!!!!! NOTE !!!!!!!!!!
   *
   * The `DataFlow::FlowLabel` class became deprecated together with
   * `DataFlow::Configuration` and `TaintTracking::Configuration`.
   *
   * There is now no standard library taking advantage of `DataFlow::FlowLabel`
   * specifically, so we shouldn't expect our pre-labels and post-labels to
   * be propagated along with steps in `LogInjection::Configuration.isAdditionalFlowStep`!
   */

  override predicate isAdditionalFlowStep(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel preLabel,
    DataFlow::FlowLabel postLabel
  ) {
    /* 1. From a remote flow source to a logging function. */
    exists(UI5LogInjectionConfiguration config |
      config.isAdditionalFlowStep(start, end) and
      preLabel = "not-logged" and
      postLabel = "logged"
    )
    /*
     * 2. From a logging function to a log entry: a shared flow step
     * `LogArgumentToListener` in FlowSteps.qll, implemented as a
     * `DataFlow::SharedFlowStep`.
     */

    /*
     * 3. From a log entry to an HTTP sending function.
     */

    }

  override predicate isSink(DataFlow::Node node, DataFlow::FlowLabel label) {
    node instanceof ClientRequestInjectionVector and
    label = "accessed"
  }
}

from UI5LogEntryToHttp cfg, UI5PathNode source, UI5PathNode sink, UI5PathNode primarySource
where
  cfg.hasFlowPath(source.getPathNode(), sink.getPathNode()) and
  primarySource = source.getAPrimarySource()
select sink, primarySource, sink, "Outbound network request depends on $@ log data.", primarySource,
  "user-provided"
// import DataFlow::PathGraph
// from UI5LogEntryToHttp cfg, DataFlow::PathNode source, DataFlow::PathNode sink
// where cfg.hasFlowPath(source, sink)
// select sink, source, sink, "Outbound network request depends on $@ log data.", source,
//   "user-provided"
