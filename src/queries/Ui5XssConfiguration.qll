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

  /**
   * Additional Flow Step:
   * Binding path in the model <-> control metadata
   */
  private predicate bidiModelControl(DataFlow::Node start, DataFlow::Node end) {
    exists(Project p, DataFlow::SourceNode property, Metadata metadata, UI5BoundNode node |
      // same project
      p.isInThisProject(metadata.getFile()) and
      p.isInThisProject(node.getFile()) and
      // same control
      metadata.getControl().getName() = node.getBindingPath().getControlName() and
      //restrict to interesting property types
      property.getAPropertySource("type").getStringValue() = ["string"] and
      property = metadata.getProperty(node.getBindingPath().getPropertyName()) and
      (
        start = property and end = node
        or
        start = node and end = property
      )
    )
  }

  override predicate isAdditionalFlowStep(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    inLabel = "taint" and
    outLabel = "taint" and
    (
      bidiModelControl(start, end)
      or
      exists(string propName, Metadata metadata, UI5BoundNode node |
        // getAWrite -> control metadata
        start = metadata.getAWrite(propName).getArgument(1) and
        end = metadata.getProperty(propName)
        or
        // control metadata -> getTitle
        start = metadata.getProperty(propName) and
        end = metadata.getARead(propName)
      )
      or
      // Modelling binding path -> getProperty('/path')
      exists(UI5BoundNode p, GetBoundValue getP |
        start = p and
        end = getP and
        p = getP.getBind()
      )
      or
      // Modelling setProperty('/path') -> binding path
      exists(UI5BoundNode p, SetBoundValue setP |
        start = setP and
        end = p and
        p = setP.getBind()
      )
    )
  }
}

class UI5BoundNode extends DataFlow::Node {
  UI5BindingPath path;

  UI5BindingPath getBindingPath() { result = path }

  UI5BoundNode() {
    exists(Property p |
      // The property bond to an XMLView source
      this.(DataFlow::PropRef).getPropertyNameExpr() = p.getNameExpr() and
      path.getAbsolutePath() = constructPathString(path.getModel().(JsonModel).getContent(), p)
    )
  }
}

class UI5ModelSource extends UI5BoundNode {
  UI5View view;

  UI5View getView() { result = view }

  UI5ModelSource() { path = view.getASource() }
}

/**
 * Extract the correct locations based on the type of sink
 */
class UI5ModelSink extends UI5BoundNode {
  UI5ModelSink() { path = any(UI5View view).getAnHtmlISink() }
}

class GetBoundValue extends DataFlow::Node {
  UI5BoundNode bind;

  GetBoundValue() {
    exists(DataFlow::CallNode getProp |
      // direct access to a binding path
      this = getProp and
      getProp.getCalleeName() = ["getProperty", "getObject"] and
      bind.getBindingPath().getAbsolutePath() = getProp.getArgument(0).getStringValue() and
      bind.getBindingPath().getModel() = getProp.getReceiver().getALocalSource()
    )
  }

  UI5BoundNode getBind() { result = bind }
}

class SetBoundValue extends DataFlow::Node {
  UI5BoundNode bind;

  SetBoundValue() {
    exists(DataFlow::CallNode setProp |
      // direct access to a binding path
      this = setProp.getArgument(1) and
      setProp.getCalleeName() = ["setProperty", "setObject"] and
      bind.getBindingPath().getAbsolutePath() = setProp.getArgument(0).getStringValue() and
      bind.getBindingPath().getModel() = setProp.getReceiver().getALocalSource()
    )
  }

  UI5BoundNode getBind() { result = bind }
}

Locatable getUI5SourceLocation(DataFlow::SourcePathNode source) {
  if source.getNode() instanceof UI5BoundNode
  then
    result = source.getNode().(UI5BoundNode).getBindingPath() and
    result = any(UI5View view).getASource()
  else result = source.getNode().asExpr()
}

Locatable getUI5SinkLocation(DataFlow::SinkPathNode sink) {
  if sink.getNode() instanceof UI5BoundNode
  then
    result = sink.getNode().(UI5BoundNode).getBindingPath() and
    result = any(UI5View view).getAnHtmlISink()
  else result = sink.getNode().asExpr()
}
