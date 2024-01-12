import javascript
import semmle.javascript.dataflow.DataFlow as StdLibDataFlow
import advanced_security.javascript.frameworks.ui5.UI5
import advanced_security.javascript.frameworks.ui5.UI5View
import advanced_security.javascript.frameworks.ui5.UI5AMDModule
import advanced_security.javascript.frameworks.ui5.RemoteFlowSources
import advanced_security.javascript.frameworks.ui5.dataflow.FlowSteps
private import StdLibDataFlow::DataFlow::PathGraph as DataFlowPathGraph

/* TODO: Legacy code */
predicate isAdditionalFlowStep(DataFlow::Node start, DataFlow::Node end) {
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

class LocalModelContentBoundBidirectionallyToHtmlISinkControl extends DomBasedXss::Sink {
  UI5BindingPath bindingPath;
  UI5Control controlDeclaration;

  LocalModelContentBoundBidirectionallyToHtmlISinkControl() {
    exists(UI5InternalModel internalModel |
      this = bindingPath.getNode() and
      internalModel.getArgument(0).getALocalSource().asExpr() =
        this.(PropWrite).getPropertyNameExpr().getParent+() and
      any(UI5View view).getAnHtmlISink() = bindingPath and
      internalModel.(JsonModel).isTwoWayBinding() and
      controlDeclaration = bindingPath.getControlDeclaration()
    )
  }

  UI5BindingPath getBindingPath() { result = bindingPath }

  UI5Control getControlDeclaration() { result = controlDeclaration }
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
          .getLocation()
          .hasLocationInfo(filepath, startline, startcolumn, endline, endcolumn)
    }

    DataFlow::PathNode getPathNode() { result.getNode() = this.asDataFlowNode() }

    UI5PathNode getAPrimarySource() {
      if this.asDataFlowNode() instanceof LocalModelContentBoundBidirectionallyToSourceControl
      then
        result.asUI5BindingPathNode() =
          this.asDataFlowNode()
              .(LocalModelContentBoundBidirectionallyToSourceControl)
              .getBindingPath()
      else result = this
    }

    UI5PathNode getAPrimaryHtmlISink() {
      if
        this.asDataFlowNode() instanceof LocalModelContentBoundBidirectionallyToHtmlISinkControl or
        this.asDataFlowNode() instanceof UI5ExternalModel // TODO: Narrow it down to ExternalModelBoundToHtmlISinkControl
      then
        result.asUI5BindingPathNode() =
          this.asDataFlowNode()
              .(LocalModelContentBoundBidirectionallyToHtmlISinkControl)
              .getBindingPath()
        or
        /* Look for the control with the binding path associated with the model */
        result.asUI5BindingPathNode().getModel().(UI5ExternalModel) = this.asDataFlowNode() and
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

  private module CustomPathGraphEdges {
    /**
     * An edge from the binding path in a view to a corresponding content of an internal model. e.g.
     * Given an XML declaration of a use of the control C, and a local model `oModel` it refers to:
     * ```xml
     * <C x="{/y}"/>
     * ```
     * and
     * ```javascript
     * let oModel = new JSONModel({ y: null });
     * ```
     *
     * establishes an edge from `x="{/y}"` to `y: null`.
     *
     * c.f. `FlowSteps::InternalModelContentToCustomMetadataPropertyStep`.
     */
    predicate bindingPathToInternalModelContent(
      UI5PathNode ui5PathNodePred, UI5PathNode ui5PathNodeSucc
    ) {
      exists(UI5BindingPath bindingPath |
        bindingPath = ui5PathNodePred.asUI5BindingPathNode() and
        ui5PathNodeSucc.asDataFlowNode() = bindingPath.getNode()
      )
    }

    /**
     * An edge from a content of an internal model to the corresponding binding path in a view, which makes it an edge in the opposite direction as of `bindingPathToInternalModelContent` above.
     * In order to ensure that the edge indeed holds, we check if the model's binding mode is declared as two-way.
     *
     * c.f. `FlowSteps::InternalModelContentToCustomMetadataPropertyStep`.
     */
    predicate internalModelContentToBindingPath(
      UI5PathNode ui5PathNodePred, UI5PathNode ui5PathNodeSucc
    ) {
      exists(UI5BindingPath bindingPath, UI5InternalModel internalModel, PropWrite property |
        bindingPath = ui5PathNodeSucc.asUI5BindingPathNode() and
        property = bindingPath.getNode() and
        ui5PathNodePred.asDataFlowNode() = property and
        internalModel.(JsonModel).getAProperty() = property and // TODO: Generalize to UI5InternalModel
        internalModel.(JsonModel).isTwoWayBinding() // TODO: Generalize to UI5InternalModel
      )
    }
  }

  query predicate edges(UI5PathNode ui5PathNodePred, UI5PathNode ui5PathNodeSucc) {
    /* Include all existing dataflow edges */
    exists(DataFlow::PathNode pathNodeFrom, DataFlow::PathNode pathNodeTo |
      pathNodeFrom.getNode() = ui5PathNodePred.asDataFlowNode() and
      pathNodeTo.getNode() = ui5PathNodeSucc.asDataFlowNode() and
      DataFlowPathGraph::edges(pathNodeFrom, pathNodeTo)
    ) and
    /* ========= TODO: Legacy code ========= */
    /* Exclude duplicate edge from model to handler parameter */
    not exists(UI5Handler h |
      ui5PathNodePred.asDataFlowNode() = h.getBindingPath().getNode() and
      ui5PathNodeSucc.asDataFlowNode() = h.getParameter(0)
    )
    or
    /* Flow to event handler parameter through the binding argument */
    exists(UI5Handler h |
      ui5PathNodePred.asUI5BindingPathNode() = h.getBindingPath() and
      ui5PathNodeSucc.asDataFlowNode() = h.getParameter(0)
    )
    or
    /* ===================================== */
    CustomPathGraphEdges::bindingPathToInternalModelContent(ui5PathNodePred, ui5PathNodeSucc)
    or
    CustomPathGraphEdges::internalModelContentToBindingPath(ui5PathNodePred, ui5PathNodeSucc)
    or
    /* Model with contents not statically observable */
    ui5PathNodePred.asUI5BindingPathNode().getModel() = ui5PathNodeSucc.asDataFlowNode() and
    ui5PathNodePred.asUI5BindingPathNode() = any(UI5View view).getASource()
    or
    ui5PathNodeSucc.asUI5BindingPathNode().getModel() = ui5PathNodePred.asDataFlowNode() and
    ui5PathNodeSucc.asUI5BindingPathNode() = any(UI5View view).getAnHtmlISink()
  }
}
