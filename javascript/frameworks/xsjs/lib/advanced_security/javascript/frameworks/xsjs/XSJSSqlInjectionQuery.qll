import javascript
import advanced_security.javascript.frameworks.xsjs.AsyncXSJS
import semmle.javascript.security.dataflow.SqlInjectionQuery as SqlInjection

class XSJSDBConnectionPrepareStatementArgument extends DataFlow::ValueNode {
  XSJSDBConnectionPrepareStatementArgument() {
    exists(XSJSDatabaseConnectionReference connection |
      this = connection.getStatementPreparingCall().getArgument(0)
    )
  }

  predicate isConcatenated() { this.getAPredecessor+() instanceof StringOps::ConcatenationNode }
}

class Configuration extends TaintTracking::Configuration {
  Configuration() { this = "XSJS SQL Injection Query" }

  override predicate isSource(DataFlow::Node start) {
    super.isSource(start) or
    start instanceof RemoteFlowSource
  }

  override predicate isSink(DataFlow::Node end) {
    super.isSink(end) or
    end.(XSJSDBConnectionPrepareStatementArgument).isConcatenated()
  }
}
