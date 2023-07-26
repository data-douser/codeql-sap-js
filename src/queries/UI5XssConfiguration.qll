import javascript
import models.UI5::UI5
import models.UI5View
import models.UI5AMDModule
import semmle.javascript.security.dataflow.DomBasedXssQuery as DomBasedXss

class UI5XssConfiguration extends DomBasedXss::Configuration {
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
      exists(string propName, Metadata metadata |
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

/**
 * Models dataflow nodes bound to a UI5 View via binding path
 */
class UI5BoundNode extends DataFlow::Node {
  UI5BindingPath bindingPath;

  UI5BindingPath getBindingPath() { result = bindingPath }

  UI5BoundNode() {
    exists(Property p |
      // The property bound to an UI5View source
      this.(DataFlow::PropRef).getPropertyNameExpr() = p.getNameExpr() and
      bindingPath.getAbsolutePath() =
        constructPathString(bindingPath.getModel().(JsonModel).getContent(), p)
    )
  }
}

/**
 * An remote source associated with a `UI5BoundNode`
 */
class UI5ModelSource extends UI5BoundNode, DomBasedXss::Source {
  UI5ModelSource() { bindingPath = any(UI5View view).getASource() }
}

/**
 * An html injection sink associated with a `UI5BoundNode`
 */
class UI5ModelSink extends UI5BoundNode, DomBasedXss::Sink {
  UI5View view;

  UI5ModelSink() {
    not view.getController().getModel().(JsonModel).isOneWayBinding() and
    bindingPath = view.getAnHtmlISink()
  }
}

/**
 * Models calls to `Model.getProperty` and `Model.getObject`
 */
class GetBoundValue extends DataFlow::CallNode {
  UI5BoundNode bind;

  UI5BoundNode getBind() { result = bind }

  GetBoundValue() {
    // direct read access to a binding path
    this.getCalleeName() = ["getProperty", "getObject"] and
    bind.getBindingPath().getAbsolutePath() = this.getArgument(0).getStringValue() and
    bind.getBindingPath().getModel() = this.getReceiver().getALocalSource()
  }
}

/**
 * Models calls to `Model.setProperty` and `Model.setObject`
 */
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

Locatable getUI5SourceLocation(DataFlow::Node node) {
  result = node.(UI5ModelSource).getBindingPath() and
  result = any(UI5View view).getASource()
  or
  result = node.asExpr()
}

Locatable getUI5SinkLocation(DataFlow::Node node) {
  result = node.(UI5ModelSink).getBindingPath() and
  result = any(UI5View view).getAnHtmlISink()
  or
  result = node.asExpr()
}
