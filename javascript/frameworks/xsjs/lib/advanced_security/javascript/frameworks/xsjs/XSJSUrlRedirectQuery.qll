import javascript
import advanced_security.javascript.frameworks.xsjs.AsyncXSJS
import semmle.javascript.security.dataflow.ServerSideUrlRedirectQuery as UrlRedirect

class Configuration extends TaintTracking::Configuration {
  Configuration() { this = "XSJS URL Redirect Query" }

  override predicate isSource(DataFlow::Node start) {
    exists(UrlRedirect::Configuration urlRedirectConfiguration |
      urlRedirectConfiguration.isSource(start)
    ) or
    start instanceof RemoteFlowSource
  }

  override predicate isSink(DataFlow::Node end) {
    exists(XSJSRequestOrResponseHeaders headers |
      end = headers.getHeaderSetCall("location").getArgument(1)
    )
  }
}
