import javascript
import queries.UI5XssConfiguration
private import DataFlow::PathGraph as DataFlowPathGraph

module PathGraph {
    newtype TNode =
        TUI5BindingPathNode(UI5BindingPath path)
        or
        TDataFlowPathNode(DataFlow::PathNode node)

    class UI5PathNode extends TNode {
        
        DataFlow::PathNode asDataFlowPathNode() {
            this = TDataFlowPathNode(result)
        }

        UI5BindingPath asUI5BindingPathNode() {
            this = TUI5BindingPathNode(result)
        }

        string toString() {
            result = this.asDataFlowPathNode().toString()
            or
            result = this.asUI5BindingPathNode().toString()
        }

        predicate hasLocationInfo(string filepath, int startline, int startcolumn, int endline, int endcolumn) {
            this.asDataFlowPathNode().getNode().hasLocationInfo(filepath, startline, startcolumn, endline, endcolumn)
            or
            exists(Location loc |
            this.asUI5BindingPathNode().getLocation() = loc |
            loc.getFile().getAbsolutePath() = filepath and
            loc.getStartLine() = startline and
            loc.getStartColumn() = startcolumn and
            loc.getEndLine() = endline and
            loc.getEndColumn() = endcolumn
            )
        }

        UI5PathNode getMostAccurateSource() {
            not this.asDataFlowPathNode().getNode() instanceof UI5ModelSource and
            this.asDataFlowPathNode() = result.asDataFlowPathNode() 
            or
            this.asDataFlowPathNode().getNode().(UI5ModelSource).getBindingPath() = result.asUI5BindingPathNode() and
            result.asUI5BindingPathNode() = any(UI5View view).getASource()
        }

        UI5PathNode getMostAccurateSink() {
            not this.asDataFlowPathNode().getNode() instanceof UI5ModelSink and
            this.asDataFlowPathNode() = result.asDataFlowPathNode()
            or
            this.asDataFlowPathNode().getNode().(UI5ModelSink).getBindingPath() = result.asUI5BindingPathNode()
            and result.asUI5BindingPathNode() = any(UI5View view).getAnHtmlISink()
        }
    }

    query predicate nodes(UI5PathNode nd) {
        exists(nd.asUI5BindingPathNode())
        or
        DataFlowPathGraph::nodes(nd.asDataFlowPathNode())
    }

    query predicate edges(UI5PathNode pred, UI5PathNode succ) {
        DataFlowPathGraph::edges(pred.asDataFlowPathNode(), succ.asDataFlowPathNode())
        or
        pred.asUI5BindingPathNode() = succ.asDataFlowPathNode().getNode().(UI5ModelSource).getBindingPath() and
        pred.asUI5BindingPathNode() = any(UI5View view).getASource()
        or
        succ.asUI5BindingPathNode() = pred.asDataFlowPathNode().getNode().(UI5ModelSink).getBindingPath() and
        succ.asUI5BindingPathNode() = any(UI5View view).getAnHtmlISink()
    }
}