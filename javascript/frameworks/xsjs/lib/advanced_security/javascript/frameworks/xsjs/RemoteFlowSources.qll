import javascript
import DataFlow
import advanced_security.javascript.frameworks.xsjs.AsyncXSJS

class XSJSZipClassInstantiation extends NewNode {
  XSJSZipClassInstantiation() {
    exists(XSJSUtilNamespace util |
      this = util.getAConstructorInvocation("Zip") and
      this.getAnArgument().getALocalSource() instanceof RemoteFlowSource
    )
  }
}

private SourceNode xsjsRequestBody(DataFlow::TypeTracker t) {
  t.start() and
  exists(XSJSRequest dollarRequest | result = dollarRequest.getAPropertyRead("body"))
  or
  exists(DataFlow::TypeTracker t2 | result = xsjsRequestBody(t2).track(t2, t))
}

private SourceNode xsjsRequestBody() { result = xsjsRequestBody(DataFlow::TypeTracker::end()) }

class XSJSRequestBody extends SourceNode {
  XSJSRequestBody() {
    exists(SourceNode dollarRequestBody | dollarRequestBody = xsjsRequestBody() |
      this = dollarRequestBody or
      this = dollarRequestBody.getAMethodCall(["asArrayBuffer", "asString", "asWebRequest"])
    )
  }
}
