import javascript
import advanced_security.javascript.frameworks.ui5.dataflow.DataFlow
import advanced_security.javascript.frameworks.ui5.dataflow.DataFlow::UI5PathGraph
import semmle.javascript.security.dataflow.LogInjectionQuery as LogInjection

class UI5LogInjectionConfiguration extends LogInjection::LogInjectionConfiguration {
  override predicate isSource(DataFlow::Node node) { node instanceof RemoteFlowSource }

  override predicate isSink(DataFlow::Node node) {
    node = ModelOutput::getASinkNode("ui5-log-injection").asSink()
  }
}
