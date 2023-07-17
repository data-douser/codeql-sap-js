import javascript
import models.UI5::UI5
import models.UI5View
import models.UI5AMDModule
import semmle.javascript.security.dataflow.DomBasedXssQuery as DomBasedXss
import DataFlow::PathGraph

class Ui5XssConfiguration extends TaintTracking::Configuration {
  Ui5XssConfiguration() { this = "Ui5XssConfiguration" }

  override predicate isSource(DataFlow::Node source) {
    source instanceof DomBasedXss::Source or source instanceof UI5ModelSource
  }

  override predicate isSink(DataFlow::Node sink) {
    sink instanceof DomBasedXss::Sink or sink instanceof UI5ModelSink
  }

  override predicate isAdditionalFlowStep(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    inLabel = "taint" and
    outLabel = "taint" and
    (
      /*
       * Modeling setTitle --(1)--> title property --(2)--> getTitle
       */

      exists(string propName, Metadata m |
        // 1. Starting from getAWrite
        start = m.getAWrite(propName).getArgument(1) and
        // 2. Ending at the title property
        end = m.getProperty(propName)
        or
        // 1. Starting from the title property
        start = m.getProperty(propName) and
        // 2. Ending at getTitle
        end = m.getARead(propName)
      )
      or
      exists(PropertySource p, GetPropertySource getP |
        start = p and
        end = getP and
        p.getPath() = getP.getPath()
      )
      or
      exists(PropertySink p, SetPropertySink setP |
        start = setP and
        end = p and
        p.getPath() = setP.getPath()
      )
    )
  }
}

class UI5ModelSource extends DataFlow::Node {
  UI5ModelSource() {
    this instanceof PropertySource
    or
    this instanceof GetPropertySource and
    not exists(PropertySource p | p.getPath() = this.(GetPropertySource).getPath())
  }

  UI5BindingPath getPath() {
    result = [this.(PropertySource).getPath(), this.(GetPropertySource).getPath()]
  }
}

class PropertySource extends DataFlow::Node {
  UI5BindingPath path;

  PropertySource() {
    exists(UI5View view, Property p | path = view.getASource() |
      // The property bond to an XMLView source
      this.(DataFlow::PropRef).getPropertyNameExpr() = p.getNameExpr() and
      path.getAbsolutePath() = constructPathString(path.getModel().(JsonModel).getContent(), p)
    )
  }

  UI5BindingPath getPath() { result = path }
}

class GetPropertySource extends DataFlow::Node {
  UI5BindingPath path;

  GetPropertySource() {
    // direct access to a binding path
    exists(UI5View view, DataFlow::CallNode getProp | path = view.getASource() |
      this = getProp and
      getProp.getCalleeName() = ["getProperty", "getObject"] and
      path.getAbsolutePath() = getProp.getArgument(0).getStringValue() and
      path.getModel() = getProp.getReceiver().getALocalSource()
    )
  }

  UI5BindingPath getPath() { result = path }
}

/**
 * Extract the correct locations based on the type of sink
 */
class UI5ModelSink extends DataFlow::Node {
  UI5ModelSink() {
    this instanceof PropertySink
    or
    this instanceof SetPropertySink and
    not exists(PropertySink p | p.getPath() = this.(SetPropertySink).getPath())
  }

  UI5BindingPath getPath() {
    result = [this.(PropertySink).getPath(), this.(SetPropertySink).getPath()]
  }
}

class PropertySink extends DataFlow::Node {
  UI5BindingPath path;

  PropertySink() {
    exists(UI5View view, Property p | path = view.getAnHtmlISink() |
      // The property bound to an XMLView source
      this.(DataFlow::PropRef).getPropertyNameExpr() = p.getNameExpr() and
      path.getAbsolutePath() = constructPathString(path.getModel().(JsonModel).getContent(), p)
    )
  }

  UI5BindingPath getPath() { result = path }
}

class SetPropertySink extends DataFlow::Node {
  UI5BindingPath path;

  SetPropertySink() {
    exists(UI5View view, DataFlow::CallNode setProp | path = view.getAnHtmlISink() |
      // direct access to a binding path
      this = setProp.getArgument(1) and
      setProp.getCalleeName() = ["setProperty", "setObject"] and
      path.getAbsolutePath() = setProp.getArgument(0).getStringValue() and
      path.getModel() = setProp.getReceiver().getALocalSource()
    )
  }

  UI5BindingPath getPath() { result = path }
}

Locatable getSourceLocation(DataFlow::SourcePathNode source) {
  if source.getNode() instanceof UI5ModelSource
  then result = source.getNode().(UI5ModelSource).getPath()
  else result = source.getNode().asExpr()
}

Locatable getSinkLocation(DataFlow::SinkPathNode sink) {
  if sink.getNode() instanceof UI5ModelSink
  then result = sink.getNode().(UI5ModelSink).getPath()
  else result = sink.getNode().asExpr()
}
