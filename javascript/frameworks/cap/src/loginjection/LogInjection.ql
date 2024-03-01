/**
 * @name CAP Log injection
 * @description Building log entries from user-controlled sources is vulnerable to
 *              insertion of forged log entries by a malicious user.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 6.1
 * @precision medium
 * @id js/cap-log-injection
 * @tags security
 */

import javascript
import DataFlow::PathGraph
import semmle.javascript.security.dataflow.LogInjectionQuery
import advanced_security.javascript.frameworks.cap.CDS

/**
 * A taint-tracking configuration for untrusted user input used in log entries.
 */
class CapLogIConfiguration extends TaintTracking::Configuration {
  CapLogIConfiguration() { this = "CapLogInjection" }

  override predicate isSource(DataFlow::Node source) { source instanceof Source }

  override predicate isSink(DataFlow::Node sink) { sink instanceof CDS::CdsLogSink }

  override predicate isSanitizer(DataFlow::Node node) { node instanceof Sanitizer }
}

from CapLogIConfiguration config, DataFlow::PathNode source, DataFlow::PathNode sink
where config.hasFlowPath(source, sink)
select sink.getNode(), source, sink, "Log entry depends on a $@.", source.getNode(),
  "user-provided value"
