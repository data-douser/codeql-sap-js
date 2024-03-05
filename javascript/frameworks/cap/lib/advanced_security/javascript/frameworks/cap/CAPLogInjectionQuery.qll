import javascript
import semmle.javascript.dataflow.DataFlow
import semmle.javascript.security.dataflow.LogInjectionQuery
import advanced_security.javascript.frameworks.cap.RemoteFlowSources
import advanced_security.javascript.frameworks.cap.CDS
import advanced_security.javascript.frameworks.cap.dataflow.FlowSteps

/**
 * A logger obtained by a call to `log` on a CDS facade. Each logger is associated with
 * its unique name.
 */
class CdsLogger extends MethodCallNode {
  string name;

  CdsLogger() {
    exists(CdsFacade cds |
      this = cds.getMember("log").getACall() and
      name = this.getArgument(0).getALocalSource().asExpr().(StringLiteral).getValue()
    )
  }

  string getName() { result = name }
}

/**
 * Arguments of calls to `cds.log.{trace, debug, info, log, warn, error}`
 */
class CdsLogSink extends DataFlow::Node {
  CdsLogSink() {
    exists(CdsLogger log, MethodCallNode loggingMethod |
      this = loggingMethod.getAnArgument() and
      not this.asExpr() instanceof Literal and
      not this.asExpr() instanceof TemplateLiteral and
      loggingMethod.getReceiver().getALocalSource() = log and
      loggingMethod.getMethodName() = ["trace", "debug", "info", "log", "warn", "error"]
    )
  }
}

class Configuration extends LogInjectionConfiguration {
  override predicate isSource(DataFlow::Node start) {
    super.isSource(start) or
    start instanceof RemoteFlowSource
  }

  override predicate isSink(DataFlow::Node node) { node instanceof CdsLogSink }
}
