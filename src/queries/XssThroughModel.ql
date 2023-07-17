/**
 * @id xss-through-model
 * @name XSS through a model
 * @kind problem
 */

import javascript
import models.UI5::UI5
import models.UI5View
import semmle.javascript.security.dataflow.DomBasedXssQuery

DataFlow::CallNode getGetterCall(UI5BindingPath path) {
  exists(XmlView view |
    // TODO: matching control name
    // TODO: source in the JSONModel literal+ edge from Model to getProperty
    result.getCalleeName() = ["getProperty", "getObject"] and
    result.getArgument(0).getStringValue() = path.getAbsolutePath() and
    view.getASource() = path and
    view.getController().getModel().(JsonModel).getPathString() = path.getAbsolutePath()
  )
}

DataFlow::CallNode getSetterCall(UI5BindingPath path) {
  exists(XmlView view |
    result.getCalleeName() = ["setProperty", "setObject"] and
    path = view.getAnHtmlISink() and
    result.getArgument(0).getStringValue() = path.getAbsolutePath() and
    view.getController().getModel().(JsonModel).getPathString() = path.getAbsolutePath()
  )
}

predicate modelHasFlowBetween(UI5BindingPath start, UI5BindingPath end) {
  /* They are completely identical, hence there's a trivial zero-step flow */
  start.getAbsolutePath() = end.getAbsolutePath() and
  start.getLocation() = end.getLocation()
  or
  /* There's a non-trivial flow between the binding paths through get/setProperty */
  getGetterCall(start).flowsTo(getSetterCall(end).getArgument(1))
}

from
  XmlView xmlView, XmlBindingPath startPath, XmlBindingPath endPath, UI5Model model, XmlControl start,
  XmlControl end
where
  not xmlView.getController().getModel().(JsonModel).isOneWayBinding() and
  start = xmlView.getXmlControl() and
  start.accessesModel(model, startPath) and
  start.isXssSource() and
  end = xmlView.getXmlControl() and
  end.accessesModel(model, endPath) and
  end.isXssSink() and
  modelHasFlowBetween(startPath, endPath)
select xmlView,
  "This XML View writes to $@ using $@ ($@) and reads from it directly through $@ ($@).", model,
  model.toString(), start, start.toString(), startPath, startPath.getAbsolutePath(), end,
  end.toString(), endPath, endPath.getAbsolutePath()
