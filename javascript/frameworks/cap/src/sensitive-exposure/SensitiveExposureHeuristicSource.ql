/**
 * @name Insertion of sensitive information into log files
 * @description Writing heuristically sensitive information to log files can allow that
 *              information to be leaked to an attacker more easily.
 * @kind path-problem
 * @problem.severity warning
 * @security-severity 7.5
 * @precision low
 * @id js/cap-sensitive-log-heurisitic-source
 * @tags security
 *       external/cwe/cwe-532
 */

import javascript
import advanced_security.javascript.frameworks.cap.CDS
import advanced_security.javascript.frameworks.cap.CAPLogInjectionQuery
private import semmle.javascript.security.dataflow.CleartextLoggingCustomizations::CleartextLogging as CleartextLogging
import DataFlow::PathGraph

class SensitiveLogExposureConfig extends TaintTracking::Configuration {
  SensitiveLogExposureConfig() { this = "SensitiveLogExposure" }

  override predicate isSource(DataFlow::Node source) { source instanceof CleartextLogging::Source }

  override predicate isSink(DataFlow::Node sink) { sink instanceof CdsLogSink }
}

from SensitiveLogExposureConfig config, DataFlow::PathNode source, DataFlow::PathNode sink
where config.hasFlowPath(source, sink)
select sink, source, sink, "This logs sensitive data returned by $@ as clear text.",
  source.getNode(), source.getNode().(CleartextLogging::Source).describe()
