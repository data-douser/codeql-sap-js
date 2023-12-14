import javascript
import advanced_security.javascript.frameworks.ui5.UI5::UI5
import advanced_security.javascript.frameworks.ui5.UI5View
import advanced_security.javascript.frameworks.ui5.UI5AMDModule
private import DataFlow::PathGraph as DataFlowPathGraph

module UI5DataFlow {
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
            .getControlDeclaration()
            .getDefinition()
            .getMetadata()
            .getProperty(propName) and
      end = externalModel
      or
      end =
        bindingPath
            .(XmlBindingPath)
            .getControlDeclaration()
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

  /** TODO */
  predicate externalModelToCustomMetadataPropertyStep(
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
    )
  }

  /** Control metadata property being the intermediate flow node */
  predicate customMetadataPropertyReadStep(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    exists(PropertyMetadata property |
      // writing site -> control property
      start = property.getAWrite().getArgument(1) and
      end = property
      or
      // control property -> reading site
      start = property and
      end = property.getARead()
    ) and
    inLabel = outLabel
  }

  predicate localModelSetPropertyStep(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    exists(
      MethodCallNode setPropertyCall, ModelReference modelRef, CustomController controller,
      InternalModelManifest internalModelManifest
    |
      setPropertyCall.getMethodName() = "setProperty" and
      setPropertyCall.getReceiver().getALocalSource() = modelRef and
      /* We're applying TC + since the modelRef can be inside a callback argument. */
      modelRef.asExpr().getEnclosingFunction+() = controller.getAHandler().getFunction() and
      controller.getAModelReference() = modelRef and
      // modelRef.getModelName() can be found in manifest.js
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

  predicate localModelGetPropertyStep(
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

  predicate localModelControlMetadataStep(
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

  predicate modelDefinitionToReferenceStep(
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

  predicate modelReferenceToReadStep(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    exists(ModelReference modelReference, MethodCallNode readingMethodCall |
      readingMethodCall = modelReference.getARead() and
      start = modelReference and
      end = readingMethodCall and
      inLabel = inLabel and // any inLabel
      outLabel = outLabel // any outLabel
    )
  }

  predicate isAdditionalFlowStep(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    // bidiModelControl(start, end)
    // or
    // // handler argument node to handler parameter
    // exists(UI5Handler h |
    //   start = h.getBindingPath().getNode() and
    //   // ideally we would like to show an intermediate node where
    //   // the handler is bound to a control, but there is no sourceNode there
    //   // `end = h.getBindingPath() or start = h.getBindingPath()`
    //   end = h.getParameter(0)
    // )
    // or
    customMetadataPropertyReadStep(start, end, inLabel, outLabel)
    or
    externalModelToCustomMetadataPropertyStep(start, end, inLabel, outLabel)
    or
    localModelSetPropertyStep(start, end, inLabel, outLabel)
    or
    localModelGetPropertyStep(start, end, inLabel, outLabel)
    or
    localModelControlMetadataStep(start, end, inLabel, outLabel)
    or
    modelDefinitionToReferenceStep(start, end, inLabel, outLabel)
    or
    modelReferenceToReadStep(start, end, inLabel, outLabel)
    // /* 2. Model property being the intermediate flow node */
    // // JS object property (corresponding to binding path) -> getProperty('/path')
    // start = end.(GetBoundValue).getBoundNode()
    // or
    // // setProperty('/path') -> JS object property (corresponding to binding path)
    // end = start.(SetBoundValue).getBoundNode()
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
        webApp.getAResource() = bindingPath.getLocation().getFile()
      |
        /* ========== Case 1: The contents of the model are statically observable ========== */
        /* The relevant portion of the content of a JSONModel */
        exists(Property modelProperty, JsonModel internalModel |
          // The property bound to an UI5View source
          this.(DataFlow::PropRef).getPropertyNameExpr() = modelProperty.getNameExpr() and
          // The binding path refers to this model
          bindingPath.getAbsolutePath() = internalModel.getPathString(modelProperty)
        )
        or
        /* The URI string to the JSONModel / XMLModel constructor call */
        exists(UI5InternalModel internalModel |
          // TODO: include the import path so that it only includes `sap.ui.model.ClientModel`
          this = internalModel.getArgument(0) and
          this.asExpr() instanceof StringLiteral and
          bindingPath.getAbsolutePath() = internalModel.getPathString()
        )
        or
        /* ========== Case 2: The contents of the model are not statically observable ========== */
        exists(MethodCallNode setModelCall |
          setModelCall.getMethodName() = "setModel" and
          this.(SourceNode).flowsTo(setModelCall.getArgument(0)) and
          not this instanceof UI5ExternalModel
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
      /* TODO: remove spurious rows! */
      this = bindingPath.getView().getController().getModel().(UI5ExternalModel)
      // and not bindingPath = any(UI5InternalBoundNode b).getBindingPath()
      /*
       *      bindingpath <--many_to_one--> model <--many_to_many-->
       *     controller
       *
       *      --> crazy cross product!
       *
       *
       *      - name of the model
       *        - as extracted from the path itself (before >)
       *        - setModel(..., "name_of_the_model")
       *      - type of the model
       *        - sap.ui.model.JSONModel
       *        - sap.ui.model.ResourceModel
       */

      }
  }

  class RouteParameterAccess extends RemoteFlowSource instanceof PropRead {
    override string getSourceType() { result = "RouteParameterAccess" }

    RouteParameterAccess() {
      exists(
        ControllerHandler handler, RouteManifest routeManifest, ParameterNode handlerParameter,
        MethodCallNode getParameterCall
      |
        handler.isAttachedToRoute(routeManifest.getName()) and
        routeManifest.matchesPathString(this.getPropertyName()) and
        this.asExpr().getEnclosingFunction() = handler.getFunction() and
        handlerParameter = handler.getParameter(0) and
        getParameterCall.getMethodName() = "getParameter" and
        getParameterCall.getReceiver().getALocalSource() = handlerParameter and
        this.getBase().getALocalSource() = getParameterCall
      )
    }
  }

  // /**
  //  * A remote source associated with a `UI5InternalBoundNode`.
  //  */
  // class UI5ModelSource extends UI5DataFlow::UI5BoundNode {
  //   UI5ModelSource() { bindingPath = any(UI5View view).getASource() }
  //   // override string getSourceType() { result = "UI5 model remote flow source" }
  // }
  /**
   * An HTML injection sink associated with a `UI5InternalBoundNode`.
   */
  class UI5ModelHtmlISink extends UI5DataFlow::UI5BoundNode {
    UI5View view;

    UI5ModelHtmlISink() {
      not view.getController().getModel().(JsonModel).isOneWayBinding() and
      bindingPath = view.getAnHtmlISink()
    }
  }

  // /**
  //  * A `getProperty` or `getObject` method call on a `UI5Model` or a reference to one, i.e. `ModelReference`. These methods read from a single property of a model.
  //  */
  // class GetBoundValue extends DataFlow::MethodCallNode {
  //   UI5BoundNode boundNode;
  //   GetBoundValue() {
  //     this.getCalleeName() = ["getProperty", "getObject"] and
  //     boundNode.getBindingPath().getAbsolutePath() = this.getArgument(0).getStringValue() and
  //     exists(DataFlow::SourceNode receiver, UI5Model model |
  //       receiver = this.getReceiver().getALocalSource() and
  //       model = boundNode.getBindingPath().getModel()
  //     |
  //       model = receiver
  //       or
  //       model.getController().getAModelReference() = receiver
  //     )
  //   }
  //   UI5BoundNode getBoundNode() { result = boundNode }
  // }
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

    /**
     * ???
     */
    UI5PathNode getAPrimarySource() {
      not this.asDataFlowPathNode().getNode() instanceof UI5DataFlow::UI5BoundNode and
      this.asDataFlowPathNode() = result.asDataFlowPathNode()
      or
      this.asDataFlowPathNode().getNode().(UI5DataFlow::UI5BoundNode).getBindingPath() =
        result.asUI5BindingPathNode() and
      result.asUI5BindingPathNode() = any(UI5View view).getASource()
    }

    /**
     * ???
     */
    UI5PathNode getAPrimaryHtmlISink() {
      not this.asDataFlowPathNode().getNode() instanceof UI5DataFlow::UI5BoundNode and
      this.asDataFlowPathNode() = result.asDataFlowPathNode()
      or
      this.asDataFlowPathNode().getNode().(UI5DataFlow::UI5BoundNode).getBindingPath() =
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
      succ.asDataFlowPathNode().getNode().(UI5DataFlow::UI5BoundNode).getBindingPath() and
    pred.asUI5BindingPathNode() = any(UI5View view).getASource()
    or
    succ.asUI5BindingPathNode() =
      pred.asDataFlowPathNode().getNode().(UI5DataFlow::UI5BoundNode).getBindingPath() and
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
