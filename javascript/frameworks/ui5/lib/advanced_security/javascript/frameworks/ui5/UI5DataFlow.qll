import javascript
import advanced_security.javascript.frameworks.ui5.UI5::UI5
import advanced_security.javascript.frameworks.ui5.UI5View
import advanced_security.javascript.frameworks.ui5.UI5AMDModule
private import DataFlow::PathGraph as DataFlowPathGraph

module UI5DataFlow {
  /**
   * Holds if there is a bi-directional data flow between
   * a model and a control. What might be referred to as "model" depends:
   *
   * For an internal model,
   * it might be the constructor call or the relevant part of the argument to the call.
   * For an external model,
   * it is the argument to the `setModel` call of a controller.
   */
  private predicate bidiModelControl(DataFlow::Node start, DataFlow::Node end) {
    /* ========== Internal Model ========== */
    exists(Metadata metadata, UI5BoundNode node |
      // same project
      exists(WebApp webApp |
        webApp.getAResource() = metadata.getFile() and webApp.getAResource() = node.getFile()
      ) and
      (
        // same control
        metadata.getExtension().(CustomControl).getName() =
          node.getBindingPath().getControlQualifiedType()
        or
        // extended control
        exists(Extension subclass |
          metadata.getExtension().(CustomControl).getDefine().getExtendingDefine() =
            subclass.getDefine() and
          node.getBindingPath().getControlQualifiedType() = subclass.getName()
        )
      ) and
      exists(PropertyMetadata property |
        property = metadata.getProperty(node.getBindingPath().getPropertyName()) and
        (
          start = property and end = node
          or
          start = node and end = property
        )
      )
    )
    or
    /* ========== External Model ========== */
    exists(UI5Model externalModel, UI5BindingPath bindingPath, string propName |
      externalModel = getModelOfRelativePath(bindingPath) and
      propName = bindingPath.getPropertyName()
    |
      start =
        bindingPath
            .(XmlBindingPath)
            .getControl()
            .getDefinition()
            .getMetadata()
            .getProperty(propName) and
      end = externalModel
      or
      end =
        bindingPath
            .(XmlBindingPath)
            .getControl()
            .getDefinition()
            .getMetadata()
            .getProperty(propName) and
      start = externalModel
    )
  }

  /**
   * Gets the reference to the model to which a given relative binding path resolves to.
   */
  MethodCallNode getModelOfRelativePath(UI5BindingPath relativePath) {
    relativePath.isRelative() and
    exists(MethodCallNode bindElementCall, MethodCallNode setModelCall |
      bindElementCall.getMethodName() = "bindElement" and
      setModelCall.getMethodName() = "setModel" and
      bindElementCall.asExpr().getParent+() =
        relativePath.getView().getController().getAMethod().asExpr() and
      setModelCall.asExpr().getParent+() =
        relativePath.getView().getController().getAMethod().asExpr() and
      result.flowsTo(setModelCall.getArgument(0)) and
      result.getMethodName() = "getModel"
    )
  }

  predicate isAdditionalFlowStep(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    inLabel = "taint" and
    outLabel = "taint" and
    (
      bidiModelControl(start, end)
      or
      // handler argument node to handler parameter
      exists(UI5Handler h |
        start = h.getBindingPath().getNode() and
        // ideally we would like to show an intermediate node where
        // the handler is bound to a control, but there is no sourceNode there
        // `end = h.getBindingPath() or start = h.getBindingPath()`
        end = h.getParameter(0)
      )
      or
      /* 1. Control metadata property being the intermediate flow node */
      exists(PropertyMetadata property |
        // writing site -> control property
        start = property.getAWrite().getArgument(1) and
        end = property
        or
        // control property -> reading site
        start = property and
        end = property.getARead()
      )
      or
      /* 2. Model property being the intermediate flow node */
      // JS object property (corresponding to binding path) -> getProperty('/path')
      start = end.(GetBoundValue).getBoundNode()
      or
      // setProperty('/path') -> JS object property (corresponding to binding path)
      end = start.(SetBoundValue).getBoundNode()
    )
  }

  /**
   * A DataFlow node which some binding path refers to. This class is needed because an XML Element / JSON Objects of a view cannot themselves be a DataFlow node, so an UI5BoundNode instead represents the binding paths those declarations carry.
   * If the binding path lives in a JS code, then it is itself a UI5BoundNode.
   */
  abstract class UI5BoundNode extends DataFlow::Node {
    UI5BindingPath bindingPath;

    UI5BindingPath getBindingPath() { result = bindingPath }
  }

  /**
   * DataFlow nodes that correspond to an **internal** model and are bound to a `UI5View` via some `UI5BindingPath`.
   */
  class UI5InternalBoundNode extends UI5BoundNode {
    UI5InternalBoundNode() {
      exists(WebApp webApp |
        webApp.getAResource() = this.getFile() and
        webApp.getAResource() = bindingPath.getFile()
      |
      /* ========== Case 1: The contents of the model are statically observable ========== */
      /* The relevant portion of the content of a JSONModel */
      exists(Property modelProperty, UI5InternalModel internalModel |
        // The property bound to an UI5View source
        this.(DataFlow::PropRef).getPropertyNameExpr() = modelProperty.getNameExpr() and
        // The binding path refers to this model
        bindingPath.getAbsolutePath() = internalModel.getPathString(modelProperty)
      )
      or
      /* The URI string to the JSONModel constructor call */
      exists(UI5InternalModel internalModel |
        this = internalModel.getArgument(0) and
        this.asExpr() instanceof StringLiteral and
        bindingPath.getAbsolutePath() = internalModel.getPathString()
      )
      or
      /* ========== Case 2: The contents of the model are not statically observable ========== */
      exists(MethodCallNode setModelCall |
        setModelCall.getMethodName() = "setModel" and
        this.(SourceNode).flowsTo(setModelCall.getArgument(0)) and
        not this instanceof UI5ExternalBoundNode
        // bindingpath condition!!!!!!!!!!!!!!!!!!!!!!!11
      )
      )
  }
  }

  /**
   * DataFlow nodes that correspond to some **external** model and are bound to a `UI5View` via some `UI5BindingPath`.
   * Since `UI5ExternalModel` is an argument to a `setModel` call, `UI5ExternalBoundNode` is also a value that flows to the `setModel` call.
   * `UI5ExternalBoundNode` = `bindingPath` + `UI5ExternalModel`.
   */
  class UI5ExternalBoundNode extends UI5BoundNode {
    UI5ExternalBoundNode() {
      this = bindingPath.getView().getController().getModel().(UI5ExternalModel) and
      (
        this instanceof NewNode
        implies
        (
          forall(string internalNodeQualifier |
            internalNodeQualifier =
              [
                "sap.ui.model.json.JSONModel", // A JSON Model
                "sap.ui.model.xml.XMLModel", // An XML Model
                "sap.ui.model.resource.ResourceModel" // A Resource Model, typically for i18n
              ]
          |
            this.(NewNode).getCalleeName() != internalNodeQualifier
          ) and
          forall(RequiredObject callee, string dependencyPath |
            dependencyPath =
              [
                "sap/ui/model/json/JSONModel", // A JSON Model
                "sap/ui/model/xml/XMLModel", // An XML Model
                "sap/ui/model/resource/ResourceModel" // A Resource Model, typically for i18n
              ]
          |
            callee.flowsTo(this.(NewNode).getCalleeNode()) and
            callee.getDependencyType() = dependencyPath
          )
        )
      )
    }
  class UI5ModelSource extends UI5DataFlow::UI5BoundNode, RemoteFlowSource {
    UI5ModelSource() { bindingPath = any(UI5View view).getASource() }

    override string getSourceType() { result = "UI5 model remote flow source" }
  }

  /**
   * A remote source associated with a `UI5InternalBoundNode`.
   */
  class UI5ModelSource extends UI5DataFlow::UI5InternalBoundNode, RemoteFlowSource {
    UI5ModelSource() { bindingPath = any(UI5View view).getASource() }

    override string getSourceType() { result = "UI5 model remote flow source" }
  }

  /**
   * An HTML injection sink associated with a `UI5InternalBoundNode`.
   */
  class UI5ModelHtmlISink extends UI5DataFlow::UI5InternalBoundNode {
    UI5View view;

    UI5ModelHtmlISink() {
      not view.getController().getModel().(JsonModel).isOneWayBinding() and
      bindingPath = view.getAnHtmlISink()
    }
  }

  /**
   * A `getProperty` or `getObject` method call on a model.
   * This is a node which reads from a property of a model.
   */
  class GetBoundValue extends DataFlow::MethodCallNode {
    UI5BoundNode boundNode;

    GetBoundValue() {
      this.getCalleeName() = ["getProperty", "getObject"] and
      boundNode.getBindingPath().getAbsolutePath() = this.getArgument(0).getStringValue() and
      exists(DataFlow::SourceNode receiver, UI5Model model |
        receiver = this.getReceiver().getALocalSource() and
        model = boundNode.getBindingPath().getModel()
      |
        model = receiver
        or
        model.getController().getAModelReference() = receiver
      )
    }

    UI5BoundNode getBoundNode() { result = boundNode }
  }

  /**
   * An argument to `setProperty` or `setObject` method call on a model.
   * This is a node which writes to a property of a model.
   */
  class SetBoundValue extends DataFlow::Node {
    UI5BoundNode boundNode;

    SetBoundValue() {
      exists(DataFlow::MethodCallNode setProp |
        this = setProp.getArgument(1) and
        setProp.getCalleeName() = ["setProperty", "setObject"] and
        boundNode.getBindingPath().getAbsolutePath() = setProp.getArgument(0).getStringValue() and
        exists(DataFlow::SourceNode receiver, UI5Model model |
          receiver = setProp.getReceiver().getALocalSource()
        |
          model = boundNode.getBindingPath().getModel() and
          (
            model = receiver
            or
            model.getController().getAModelReference() = receiver
          )
        )
      )
    }

    UI5BoundNode getBoundNode() { result = boundNode }
  }
}

module UI5PathGraph {
  newtype TNode =
    TUI5BindingPathNode(UI5BindingPath path) or
    TDataFlowPathNode(DataFlow::Node node)

  class UI5PathNode extends TNode {
    DataFlow::PathNode asDataFlowPathNode() { this = TDataFlowPathNode(result.getNode()) }

    UI5BindingPath asUI5BindingPathNode() { this = TUI5BindingPathNode(result) }

    string toString() {
      result = this.asDataFlowPathNode().toString()
      or
      result = this.asUI5BindingPathNode().toString()
    }

    predicate hasLocationInfo(
      string filepath, int startline, int startcolumn, int endline, int endcolumn
    ) {
      this.asDataFlowPathNode()
          .getNode()
          .hasLocationInfo(filepath, startline, startcolumn, endline, endcolumn)
      or
      this.asUI5BindingPathNode()
          .getLocation()
          .hasLocationInfo(filepath, startline, startcolumn, endline, endcolumn)
    }

    UI5PathNode getAPrimarySource() {
      not this.asDataFlowPathNode().getNode() instanceof UI5DataFlow::UI5InternalBoundNode and
      this.asDataFlowPathNode() = result.asDataFlowPathNode()
      or
      this.asDataFlowPathNode().getNode().(UI5DataFlow::UI5InternalBoundNode).getBindingPath() =
        result.asUI5BindingPathNode() and
      result.asUI5BindingPathNode() = any(UI5View view).getASource()
    }

    UI5PathNode getAPrimaryHtmlISink() {
      not this.asDataFlowPathNode().getNode() instanceof UI5DataFlow::UI5InternalBoundNode and
      this.asDataFlowPathNode() = result.asDataFlowPathNode()
      or
      this.asDataFlowPathNode().getNode().(UI5DataFlow::UI5InternalBoundNode).getBindingPath() =
        result.asUI5BindingPathNode() and
      result.asUI5BindingPathNode() = any(UI5View view).getAnHtmlISink()
    }
  }

  query predicate nodes(UI5PathNode nd) {
    exists(nd.asUI5BindingPathNode())
    or
    DataFlowPathGraph::nodes(nd.asDataFlowPathNode())
  }

  query predicate edges(UI5PathNode pred, UI5PathNode succ) {
    // all dataflow edges
    DataFlowPathGraph::edges(pred.asDataFlowPathNode(), succ.asDataFlowPathNode()) and
    // exclude duplicate edge from model to handler parameter
    not exists(UI5Handler h |
      pred.asDataFlowPathNode().getNode() = h.getBindingPath().getNode() and
      succ.asDataFlowPathNode().getNode() = h.getParameter(0)
    )
    or
    pred.asUI5BindingPathNode() =
      succ.asDataFlowPathNode().getNode().(UI5DataFlow::UI5InternalBoundNode).getBindingPath() and
    pred.asUI5BindingPathNode() = any(UI5View view).getASource()
    or
    succ.asUI5BindingPathNode() =
      pred.asDataFlowPathNode().getNode().(UI5DataFlow::UI5InternalBoundNode).getBindingPath() and
    succ.asUI5BindingPathNode() = any(UI5View view).getAnHtmlISink()
    or
    // flow to event handler parameter through the binding argument
    pred.asDataFlowPathNode().getNode() = succ.asUI5BindingPathNode().getNode()
    or
    exists(UI5Handler h |
      pred.asUI5BindingPathNode() = h.getBindingPath() and
      succ.asDataFlowPathNode().getNode() = h.getParameter(0)
    )
  }
}
