/**
 * @name CQL query built from user-controlled sources
 * @description Building a CQL query from user-controlled sources is vulnerable to insertion of
 *              malicious code by the user.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 8.8
 * @precision high
 * @id js/cap-sql-injection
 * @tags security
 */

import javascript
import DataFlow::PathGraph
import semmle.javascript.security.dataflow.SqlInjectionCustomizations::SqlInjection
import advanced_security.javascript.frameworks.cap.CQL
import advanced_security.javascript.frameworks.cap.RemoteFlowSources

class CqlIConfiguration extends TaintTracking::Configuration {
  CqlIConfiguration() { this = "CqlInjection" }

  override predicate isSource(DataFlow::Node source) { source instanceof RemoteFlowSource }

  override predicate isSink(DataFlow::Node sink) { sink instanceof CQLSink }

  override predicate isSanitizer(DataFlow::Node node) {
    super.isSanitizer(node) or
    node instanceof Sanitizer
  }

  override predicate isAdditionalTaintStep(DataFlow::Node pred, DataFlow::Node succ) {
    //string concatenation in a clause arg taints the clause
    exists(TaintedClause clause |
      clause.getArgument() = pred.asExpr() and
      clause.asExpr() = succ.asExpr()
    )
    or
    //less precise, any concat in the alternative sql stmt construction techniques
    exists(ParseCQLTaintedClause parse |
      parse.getAnArgument() = pred and
      parse = succ
    )
  }
}

from CqlIConfiguration sql, DataFlow::PathNode source, DataFlow::PathNode sink
where sql.hasFlowPath(source, sink)
select sink.getNode(), source, sink, "This query depends on a $@.", source.getNode(),
  "user-provided value"
