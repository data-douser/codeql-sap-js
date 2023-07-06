/**
 * @id xss-through-model
 * @name XSS through a model
 * @kind problem
 */

import javascript
import models.UI5::UI5
import models.UI5View

from XmlView xmlView, Model model, XmlControl start, XmlControl end
where
  not xmlView.getController().getModel().(JsonModel).isOneWayBinding() and
  start = xmlView.getXmlControl() and
  start.accessesModel(model) and
  start.isXssSource() and
  end = xmlView.getXmlControl() and
  end.accessesModel(model) and
  end.isXssSink()
select xmlView, "This XML View writes to $@ using $@ and reads from it directly through $@.", model,
  model.toString(), start, start.toString(), end, end.toString()
