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
import advanced_security.javascript.frameworks.ui5.UI5LogInjectionQuery

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
    exists(DataFlow::PropWrite onLogEntryProp | onLogEntryProp.getPropertyName() = "onLogEntry" |
      result = onLogEntryProp.getRhs()
    )
  }
}

class UI5LogEntryFlowState extends DataFlow::FlowLabel {
  UI5LogEntryFlowState() {
    this = ["not-logged-not-accessed", "logged-not-accessed", "logged-and-accessed"]
  }
}

class UI5LogEntryToHttp extends TaintTracking::Configuration {
  UI5LogEntryToHttp() { this = "UI5 Log Entry included in an outbound HTTP request" }

  override predicate isSource(DataFlow::Node node, DataFlow::FlowLabel state) {
    node instanceof RemoteFlowSource and
    state = "not-logged-not-accessed"
  }

  override predicate isAdditionalFlowStep(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel preState,
    DataFlow::FlowLabel postState
  ) {
    exists(UI5LogInjectionConfiguration cfg |
      cfg.isAdditionalFlowStep(start, end) and
      preState = postState
    )
    or
    inSameWebApp(start.getFile(), end.getFile()) and
    start =
      ModelOutput::getATypeNode("SapLogger")
          .getMember(["debug", "error", "fatal", "info", "trace", "warning"])
          .getACall()
          .getAnArgument() and
    end = ModelOutput::getATypeNode("SapLogEntries").asSource() and
    preState = "not-logged-not-accessed" and
    postState = "logged-and-accessed"
  }

  override predicate isSink(DataFlow::Node node, DataFlow::FlowLabel state) {
    node instanceof ClientRequestInjectionVector and
    state = "logged-and-accessed"
  }
}

/**
 * Config without states for sanity check
 */
module UI5LogEntryToHttp implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node node) { node instanceof RemoteFlowSource }

  predicate isAdditionalFlowStep(DataFlow::Node start, DataFlow::Node end) {
    inSameWebApp(start.getFile(), end.getFile()) and
    start =
      ModelOutput::getATypeNode("SapLogger")
          .getMember(["debug", "error", "fatal", "info", "trace", "warning"])
          .getACall()
          .getAnArgument() and
    end = ModelOutput::getATypeNode("SapLogEntries").asSource()
  }

  predicate isSink(DataFlow::Node node) { node instanceof ClientRequestInjectionVector }
}

import DataFlow::PathGraph

from UI5LogEntryToHttp cfg, DataFlow::PathNode source, DataFlow::PathNode sink
where cfg.hasFlowPath(source, sink)
select sink, source, sink, "Outbound network request depends on $@ log data.", source,
  "user-provided"
