/**
 * @name Uncontrolled data in logging call
 * @description If unsanitized user input is written to a log entry, 
 *              a malicious user may be able to forge new log entries
 * @kind problem
 * @problem.severity error
 * @id javascript/log-injection-custom
 * @tags security
 *       external/cwe/cwe-117
 */

 import javascript
 import advanced_security.javascript.frameworks.cap.CDS
 
 class  LogInjectionConfiguration extends TaintTracking::Configuration {
    LogInjectionConfiguration(){
         this = ""
     }
     override predicate isSource(DataFlow::Node source) {
         exists(CDS::RequestSource src |
             source = src )
     }
 
     override predicate isSink(DataFlow::Node sink) { 
         exists(CDS::CdsLogSink snk |
             sink = snk )
     }
 }
 
 from LogInjectionConfiguration log , DataFlow::Node source, DataFlow::Node sink
 where log.hasFlow(source, sink)
 select sink, "Log injection vulnerability found."