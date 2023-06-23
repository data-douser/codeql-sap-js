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

  override predicate isAdditionalFlowStep(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    inLabel = "taint" and
    outLabel = "taint" and
    /*
     * Modelling setTitle --(1)--> title property --(2)--> getTitle
     */

    /* setTitle --(1)--> title property */
    exists(string propName, Metadata m |
      // 1. Starting from getAWrite
      start = m.getAWrite(propName) and
      // 2. Ending at the title property
      end = m.getAProperty(propName)
    )
    or
    /* title property --(2)--> getTitle */
    exists(string propName, Metadata m |
      // 1. Starting from the title property
      start = m.getAProperty(propName) and
      // 2. Ending at getTitle
      end = m.getARead(propName)
    )
  }
}

from XssWithCustomControl xss, UnsafeHtmlXssSource source, UnsafeHtmlXssSink sink
where xss.hasFlow(source, sink)
select source, sink
