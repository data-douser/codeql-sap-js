import javascript
import advanced_security.javascript.frameworks.ui5.UI5
import advanced_security.javascript.frameworks.ui5.UI5View
import advanced_security.javascript.frameworks.ui5.UI5AMDModule
import advanced_security.javascript.frameworks.ui5.RemoteFlowSources
private import DataFlow::PathGraph as DataFlowPathGraph

/*
 * Two-way binding implies the control can accept user input (if it has the capability .e.g aggregations) and submit it to the model of the controller whose view is declaring the use of this control.
 */

/** External model to a relevant control property */
class ExternalModelToCustomMetadataPropertyStep extends DataFlow::SharedFlowStep {
  override predicate step(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    exists(UI5BindingPath bindingPath |
      bindingPath.getModel() = start and
      end =
        bindingPath
            .getControlDeclaration()
            .getDefinition()
            .getMetadata()
            .getProperty(bindingPath.getPropertyName()) and
      // (
      //   inLabel = "taint" and outLabel = "taint"
      //   or
      //   inLabel = bindingPath.getPath() and outLabel = bindingPath.getPath()
      // )
      if any(UI5BindingPath path/* | path.getModel() = start*/ ).getPath() = inLabel
      then inLabel = bindingPath.getPath() and inLabel = outLabel
      else inLabel = outLabel
    )
  }
}

/*
 * <A a="path1"> a.control.js: {path1: {type:string}}
 * <B b="path1"> b.control.js: {path1: {type:string}}
 */

/** Control metadata property being the intermediate flow node */
class CustomMetadataPropertyReadStep extends DataFlow::SharedFlowStep {
  override predicate step(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    exists(PropertyMetadata property |
      /* Writing site -> Control property */
      start = property.getAWrite().getArgument(1) and
      end = property
      or
      /* Control property -> Reading site */
      start = property and
      end = property.getARead()
    ) and
    inLabel = outLabel
  }
}

class LocalModelSetPropertyStep extends DataFlow::SharedFlowStep {
  override predicate step(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    exists(
      MethodCallNode setPropertyCall, ModelReference modelRef, CustomController controller,
      InternalModelManifest internalModelManifest
    |
      setPropertyCall.getMethodName() = "setProperty" and
      setPropertyCall.getReceiver().getALocalSource() = modelRef and
      /* We're applying TC + since the `modelRef` can be inside a callback argument. */
      modelRef.asExpr().getEnclosingFunction+() = controller.getAHandler().getFunction() and
      controller.getAModelReference() = modelRef and
      /* `modelRef.getModelName()` can be found in manifest.js */
      internalModelManifest.getName() = modelRef.getModelName() and
      setPropertyCall.getArgument(1) = start and
      modelRef = end and
      /* Any inLabel */
      inLabel = inLabel and
      outLabel =
        modelRef.getModelName() + ">" +
          setPropertyCall.getArgument(0).getALocalSource().asExpr().getStringValue()
    )
  }
}

class LocalModelGetPropertyStep extends DataFlow::SharedFlowStep {
  override predicate step(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    exists(
      MethodCallNode getPropertyCall, ModelReference modelRefTo, ModelReference modelRefFrom,
      MethodCallNode setPropertyCall
    |
      setPropertyCall.getMethodName() = "setProperty" and
      setPropertyCall.getReceiver().getALocalSource() = modelRefFrom and
      start = modelRefFrom and
      getPropertyCall.getMethodName() = "getProperty" and
      getPropertyCall.getReceiver().getALocalSource() = modelRefTo and
      inLabel =
        modelRefTo.getModelName() + ">" +
          getPropertyCall.getArgument(0).getALocalSource().asExpr().getStringValue() and
      outLabel = "taint" and
      end = getPropertyCall and
      /*
       * Ensure that getPropertyCall and setPropertyCall are both reading/writing from/to
       * the (1) same property of the (2) same model.
       */

      getPropertyCall.getArgument(0).getALocalSource().asExpr().getStringValue() =
        setPropertyCall.getArgument(0).getALocalSource().asExpr().getStringValue() and
      modelRefFrom.getModelName() = modelRefTo.getModelName()
    )
  }
}

class LocalModelControlMetadataStep extends DataFlow::SharedFlowStep {
  override predicate step(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    exists(
      ModelReference modelRef, BindingPath bindingPath, Binding binding, CustomControl control,
      MethodCallNode setPropertyCall
    |
      setPropertyCall.getMethodName() = "setProperty" and
      setPropertyCall.getReceiver().getALocalSource() = modelRef and
      bindingPath = binding.getBindingPath() and
      bindingPath.asString() =
        modelRef.getModelName() + ">" +
          setPropertyCall.getArgument(0).getALocalSource().asExpr().getStringValue() and
      start = modelRef and
      // modelRef.getModelName() = binding.getBindingPath().getModelName() and
      binding.getBindingPath().asString() = inLabel and
      control.getMetadata().getProperty(binding.getBindingTarget().asXmlAttribute().getName()) = end and
      outLabel = "taint"
    )
  }
}

class SetModelToGetModelStep extends DataFlow::SharedFlowStep {
  override predicate step(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    exists(UI5Model modelDefinition, ModelReference modelReference |
      modelReference.getResolvedModel() = modelDefinition and
      start = modelDefinition and
      end = modelReference and
      inLabel = inLabel and // any inLabel
      outLabel = outLabel // any outLabel
    )
  }
}

class GetModelToGetPropertyStep extends DataFlow::SharedFlowStep {
  override predicate step(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    exists(ModelReference modelReference, MethodCallNode readingMethodCall |
      readingMethodCall = modelReference.getARead() and
      start = modelReference and
      end = readingMethodCall and
      inLabel = inLabel and // any inLabel
      outLabel = "taint"
    )
  }
}

predicate isAdditionalFlowStep(
  DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
  DataFlow::FlowLabel outLabel
) {
  /* Handler argument node to handler parameter */
  exists(UI5Handler h |
    start = h.getBindingPath().getNode() and
    /*
     * Ideally we would like to show an intermediate node where
     * the handler is bound to a control, but there is no sourceNode there
     * `end = h.getBindingPath() or start = h.getBindingPath()`
     */

    end = h.getParameter(0)
  )
}

class RouteParameterAccess extends RemoteFlowSource instanceof PropRead {
  override string getSourceType() { result = "RouteParameterAccess" }

  RouteParameterAccess() {
    exists(
      ControllerHandler handler, RouteManifest routeManifest, ParameterNode handlerParameter,
      MethodCallNode getParameterCall
    |
      handler.isAttachedToRoute(routeManifest.getName()) and
      this.asExpr().getEnclosingFunction() = handler.getFunction() and
      handlerParameter = handler.getParameter(0) and
      getParameterCall.getMethodName() = "getParameter" and
      getParameterCall.getReceiver().getALocalSource() = handlerParameter and
      (
        routeManifest.matchesPathString(this.getPropertyName()) and
        this.getBase().getALocalSource() = getParameterCall
        or
        /* TODO: Why does `routeManifest.matchesPathString` not work for propertyName?? */
        this.getBase().(PropRead).getBase().getALocalSource() = getParameterCall
      )
    )
  }
}

/**
 * Method calls that fetch a piece of data from a URI parameter. The rows of the resulting relation is supplied
 * from a `sourceModel` of the model-as-data extension, whose kinds are `"uri-parameter"`.
 */
class UriParameterGetMethodCall extends RemoteFlowSource {
  UriParameterGetMethodCall() {
    this = ModelOutput::getASourceNode("remote").asSource() and
    /* TODO: add more constraints to only find URIParameter-related methods/properties */
    any()
  }

  override string getSourceType() { result = "URI Parameter Data" }
}

module UI5PathGraph {
  newtype TNode =
    TUI5BindingPathNode(UI5BindingPath path) or
    TDataFlowNode(DataFlow::Node node)

  class UI5PathNode extends TNode {
    DataFlow::Node asDataFlowNode() { this = TDataFlowNode(result) }

    UI5BindingPath asUI5BindingPathNode() { this = TUI5BindingPathNode(result) }

    string toString() {
      result = this.asDataFlowNode().toString()
      or
      result = this.asUI5BindingPathNode().toString()
    }

    predicate hasLocationInfo(
      string filepath, int startline, int startcolumn, int endline, int endcolumn
    ) {
      this.asDataFlowNode().hasLocationInfo(filepath, startline, startcolumn, endline, endcolumn)
      or
      this.asUI5BindingPathNode()
          // TODO: generalize from XML
          .(XmlBindingPath)
          .hasLocationInfo(filepath, startline, startcolumn, endline, endcolumn)
    }

    DataFlow::PathNode getPathNode() { result.getNode() = this.asDataFlowNode() }

    UI5PathNode getAPrimarySource() {
      if this.asDataFlowNode() instanceof UI5ExternalModel
      then
        /* Look for the control with the binding path associated with the model */
        exists(UI5Model model, UI5BindingPath bindingPath |
          bindingPath = result.asUI5BindingPathNode() and
          this.asDataFlowNode() = model and
          model = bindingPath.getModel()
        )
      else this = result
    }

    UI5PathNode getAPrimaryHtmlISink() {
      if this.asDataFlowNode() instanceof UI5ExternalModel
      then
        /* Look for the control with the binding path associated with the model */
        result.asUI5BindingPathNode().getModel() = this.asDataFlowNode() and
        result.asUI5BindingPathNode() = any(UI5View view).getAnHtmlISink()
      else result = this
    }
  }

  query predicate nodes(UI5PathNode ui5PathNode) {
    exists(ui5PathNode.asUI5BindingPathNode())
    or
    exists(DataFlow::PathNode pathNode |
      pathNode.getNode() = ui5PathNode.asDataFlowNode() and
      DataFlowPathGraph::nodes(pathNode)
    )
  }

  query predicate edges(UI5PathNode ui5PathNodePred, UI5PathNode ui5PathNodeSucc) {
    /* Include all existing dataflow edges */
    exists(DataFlow::PathNode pathNodeFrom, DataFlow::PathNode pathNodeTo |
      pathNodeFrom.getNode() = ui5PathNodePred.asDataFlowNode() and
      pathNodeTo.getNode() = ui5PathNodeSucc.asDataFlowNode() and
      DataFlowPathGraph::edges(pathNodeFrom, pathNodeTo)
    ) and
    /* Exclude duplicate edge from model to handler parameter */
    not exists(UI5Handler h |
      ui5PathNodePred.asDataFlowNode() = h.getBindingPath().getNode() and
      ui5PathNodeSucc.asDataFlowNode() = h.getParameter(0)
    )
    or
    ui5PathNodePred.asUI5BindingPathNode().getModel() = ui5PathNodeSucc.asDataFlowNode() and
    ui5PathNodePred.asUI5BindingPathNode() = any(UI5View view).getASource()
    or
    ui5PathNodeSucc.asUI5BindingPathNode().getModel() = ui5PathNodePred.asDataFlowNode() and
    ui5PathNodeSucc.asUI5BindingPathNode() = any(UI5View view).getAnHtmlISink()
    or
    /* Flow to event handler parameter through the binding argument */
    ui5PathNodePred.asDataFlowNode() = ui5PathNodeSucc.asUI5BindingPathNode().getNode()
    or
    exists(UI5Handler h |
      ui5PathNodePred.asUI5BindingPathNode() = h.getBindingPath() and
      ui5PathNodeSucc.asDataFlowNode() = h.getParameter(0)
    )
  }
}
