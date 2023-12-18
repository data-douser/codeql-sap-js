import javascript
import advanced_security.javascript.frameworks.ui5.UI5
import advanced_security.javascript.frameworks.ui5.UI5View
import advanced_security.javascript.frameworks.ui5.UI5AMDModule
private import DataFlow::PathGraph as DataFlowPathGraph

abstract class UI5ExternalModel extends UI5Model, RemoteFlowSource {
  abstract string getName();
}

/** Model which gains content from an SAP OData service. */
class ODataServiceModel extends UI5ExternalModel {
  string modelName;

  override string getSourceType() { result = "ODataServiceModel" }

  ODataServiceModel() {
    /*
     * SKETCH
     * This is an argument to a `this.setModel` call if:
     * - this flows from a DF node corresponding to the parent component's model
     * - and the the component's manifest.json declares the DataSource as being of OData type
     */

    /*
     * e.g. this.getView().setModel(this.getOwnerComponent().getModel("booking_nobatch"))
     */

    exists(MethodCallNode setModelCall, CustomController controller |
      /*
       * 1. This flows from a DF node corresponding to the parent component's model to the `this.setModel` call
       * i.e. Aims to capture something like `this.getOwnerComponent().getModel("someModelName")` as in
       * `this.getView().setModel(this.getOwnerComponent().getModel("someModelName"))`
       */

      modelName = this.getArgument(0).getALocalSource().asExpr().(StringLiteral).getValue() and
      this.getCalleeName() = "getModel" and
      controller.getOwnerComponentRef().flowsTo(this.(MethodCallNode).getReceiver()) and
      this.flowsTo(setModelCall.getArgument(0)) and
      setModelCall.getMethodName() = "setModel" and
      setModelCall.getReceiver() = controller.getAViewReference() and
      /* 2. The component's manifest.json declares the DataSource as being of OData type */
      controller.getOwnerComponent().getExternalModelDef(modelName).getDataSource() instanceof
        ODataDataSourceManifest
    )
    or
    /*
     * A constructor call to sap.ui.model.odata.v2.ODataModel.
     */

    this instanceof NewNode and
    (
      exists(RequiredObject oDataModel |
        oDataModel.flowsTo(this.getCalleeNode()) and
        oDataModel.getDependencyType() = "sap/ui/model/odata/v2/ODataModel"
      )
      or
      this.getCalleeName() = "ODataModel"
    ) and
    modelName = "<no name>"
  }

  override string getName() { result = modelName }
}

class LocalBindingPathLabel extends DataFlow::FlowLabel {
  LocalBindingPathLabel() {
    exists(ModelReference modelRef, MethodCallNode setPropertyCall |
      setPropertyCall.getMethodName() = "setProperty" and
      setPropertyCall.getReceiver().getALocalSource() = modelRef and
      this =
        modelRef.getModelName() + ">" +
          setPropertyCall.getArgument(0).getALocalSource().asExpr().getStringValue()
    )
  }
}

/*
 * Important: flag should be "taint" when getting out of a remote model, otherwise it won't be picked up by DataFlow
 * i.e. Remote model --flag=taint--> ...
 * e.g. Remote model --flag=taint--> XML attribute (in a sink)
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
      inLabel = outLabel
      // inLabel = outLabel and
      // inLabel = bindingPath.getLiteralRepr()
    )
  }
}

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
      /* Ensure that getPropertyCall and setPropertyCall are both reading/writing from/to the (1) same property of the (2) same model. */
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
     * ideally we would like to show an intermediate node where
     *       the handler is bound to a control, but there is no sourceNode there
     *       `end = h.getBindingPath() or start = h.getBindingPath()`
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
 * Method calls that fetch a piece of data from a URI parameter. The rows of the resulting relation is supplied from a `sourceModel` of the model-as-data extension, whose kinds are `"uri-parameter"`.
 */
class UriParameterGetMethodCall extends RemoteFlowSource {
  UriParameterGetMethodCall() {
    this = ModelOutput::getASourceNode("remote").asSource() and
    /* TODO: add more constraints to only find URIParameter-related methods/properties */
    any()
  }

  override string getSourceType() { result = "URI Parameter Data" }
}

/*
 * TODO:
 * view -label1-> model -label2-> view, label1 = label2 is required
 */

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
