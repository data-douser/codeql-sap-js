import javascript
import advanced_security.javascript.frameworks.ui5.UI5
import advanced_security.javascript.frameworks.ui5.UI5View
import advanced_security.javascript.frameworks.ui5.UI5AMDModule
import advanced_security.javascript.frameworks.ui5.RemoteFlowSources
private import DataFlow::PathGraph as DataFlowPathGraph

/*
 * Two-way binding implies the control can accept user input (if it has the capability .e.g aggregations) and submit it to the model of the controller whose view is declaring the use of this control.
 */


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
