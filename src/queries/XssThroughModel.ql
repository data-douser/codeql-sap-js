/**
 * @id xss-through-model
 * @name XSS through a model
 * @kind problem
 */

import javascript
import models.UI5::UI5
import models.XmlView

from UI5XmlView xmlView
where
  not xmlView.getController().getModel().(JsonModel).isOneWayBinding() and
  exists(Model model |
    xmlView.getXmlControl().writesToModel(model) and xmlView.getXmlControl().readsFromModel(model)
  )
select xmlView
