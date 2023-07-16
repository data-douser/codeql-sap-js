/**
 * @name Client-side cross-site scripting
 * @id Ui5Xss
 * @kind path-problem
 */

import javascript
import semmle.javascript.security.dataflow.DomBasedXssQuery
import models.UI5View
import models.UI5AMDModule
import DataFlow::PathGraph

class UI5ModelSource extends Source {
  UI5BindingPath path;

  UI5ModelSource() {
    exists(CallExpr getProp, UI5View view |
      // TODO: matching control name
      // TODO: source in the JSONModel literal+ edge from Model to getProperty
      getProp.getCalleeName() = ["getProperty", "getObject"] and
      this.asExpr() = getProp and
      path = view.getASource() and
      getProp.getArgument(0).getStringValue() = path.getAbsolutePath()
    )
  }

  UI5BindingPath getPath() { result = path }
}

class UI5ModelSink extends Sink {
  UI5BindingPath path;

  UI5ModelSink() {
    exists(CallExpr setProp, UI5View view |
      setProp.getCalleeName() = ["setProperty", "setObject"] and
      this.asExpr() = setProp.getArgument(1) and
      path = view.getAnHtmlISink() and
      setProp.getArgument(0).getStringValue() = path.getAbsolutePath()
    )
  }

  UI5BindingPath getPath() { result = path }
}

Locatable getSourceLocation(DataFlow::PathNode source) {
  if source.getNode() instanceof UI5ModelSource
  then result = source.getNode().(UI5ModelSource).getPath()
  else result = source.getNode().asExpr()
}

Locatable getSinkLocation(DataFlow::PathNode sink) {
  if sink.getNode() instanceof UI5ModelSink
  then result = sink.getNode().(UI5ModelSink).getPath()
  else result = sink.getNode().asExpr()
}

from DataFlow::Configuration cfg, DataFlow::PathNode source, DataFlow::PathNode sink
where cfg.hasFlowPath(source, sink)
select getSinkLocation(sink), source, sink, "XSS vulnerability due to $@.",
  getSourceLocation(source), "user-provided value"
