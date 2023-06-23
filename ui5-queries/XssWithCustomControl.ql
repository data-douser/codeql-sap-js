import javascript
import UI5::UI5
import semmle.javascript.security.dataflow.DomBasedXssQuery

class XssWithCustomControl extends Configuration {
  override predicate isSource(DataFlow::Node source, DataFlow::FlowLabel label) {
    source instanceof UnsafeHtmlXssSource and label = "taint"
  }

  override predicate isSink(DataFlow::Node sink, DataFlow::FlowLabel label) {
    sink instanceof UnsafeHtmlXssSink and label = "taint"
  }
}

from XssWithCustomControl xss, UnsafeHtmlXssSource source, UnsafeHtmlXssSink sink
where xss.hasFlow(source, sink)
select source, sink
