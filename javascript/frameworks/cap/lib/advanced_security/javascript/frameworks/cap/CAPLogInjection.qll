import javascript
import DataFlow
import advanced_security.javascript.frameworks.cap.CDS

/**
 * A logger obtained by a call to `log` on a CDS facade. Each logger is associated with
 * its unique name.
 */
class CdsLogger extends MethodCallNode {
  string name;

  CdsLogger() {
    this = any(CdsFacade cds).getMember("log").getACall() and
    name = this.getArgument(0).getALocalSource().asExpr().(StringLiteral).getValue()
  }
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
