/**
 * @id xss-through-model
 * @name XSS through a model
 * @kind problem
 */

import javascript
import models.UI5::UI5
import models.XmlView

from UI5XmlView xmlView, Model model, UI5XmlControl start, UI5XmlControl end
where
  not xmlView.getController().getModel().(JsonModel).isOneWayBinding() and
  start = xmlView.getXmlControl() and
  start.writesToModel(model) and
  end = xmlView.getXmlControl() and
  end.readsFromModel(model)
select xmlView, model, start, end
