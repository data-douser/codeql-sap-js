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
import advanced_security.javascript.frameworks.ui5.dataflow.DataFlow::UI5PathGraph

class ClientRequestInjectionVector extends DataFlow::Node {
  ClientRequestInjectionVector() {
    exists(ClientRequest req |
      this = req.getUrl() or
      this = req.getADataNode()
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
    /*
     * NOTE: This disjunct is a labeled version of LogArgumentToListener in
     * FlowSteps.qll, a DataFlow::SharedFlowStep. As the class is considered
     * legacy on version 2.4.0, we leave the two here (labeled) and there
     * (unlabeled). This is something we should also tidy up when we migrate
     * to the newer APIs.
     */

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

from UI5LogEntryToHttp cfg, UI5PathNode source, UI5PathNode sink, UI5PathNode primarySource
where
  cfg.hasFlowPath(source.getPathNode(), sink.getPathNode()) and
  primarySource = source.getAPrimarySource()
select sink, primarySource, sink, "Outbound network request depends on $@ log data.", primarySource,
  "user-provided"
