/**
 * @id xss-custom-control
 * @name XSS with custom control
 * @kind problem
 */

import javascript
import models.UI5::UI5
import models.XmlView
import semmle.javascript.security.dataflow.DomBasedXssQuery

class XssWithCustomControl extends TaintTracking::Configuration {
  XssWithCustomControl() { this = "XssWithCustomControl" }

  override predicate isSource(DataFlow::Node source, DataFlow::FlowLabel label) {
    source instanceof UnsafeHtmlXssSource and label = "taint"
    // any()
  }

  override predicate isSink(DataFlow::Node sink, DataFlow::FlowLabel label) {
    sink instanceof UnsafeHtmlXssSink and label = "taint"
    // any()
  }

  override predicate isAdditionalFlowStep(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    inLabel = "taint" and
    outLabel = "taint" and
    /*
     * Modeling setTitle --(1)--> title property --(2)--> getTitle
     */

    /* setTitle --(1)--> title property */
    exists(string propName, Metadata m |
      // 1. Starting from getAWrite
      start = m.getAWrite(propName).getArgument(1) and
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
    // or
    /*
     * Modeling <Input value="{/model}"/> --(1)--> model --(2)--> <HTML content="{/model}"/>
     */

    // exists(UI5XmlControl xmlControl | start = xmlControl and xmlControl.writesToModel(end))
    }
}

from XssWithCustomControl xss, UnsafeHtmlXssSource source, UnsafeHtmlXssSink sink
where xss.hasFlow(source, sink)
select source, source.toString(), sink, sink.toString()
