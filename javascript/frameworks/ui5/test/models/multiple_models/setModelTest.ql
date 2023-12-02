import javascript
import advanced_security.javascript.frameworks.ui5.UI5::UI5
import advanced_security.javascript.frameworks.ui5.UI5View
import advanced_security.javascript.frameworks.ui5.UI5DataFlow

from UI5BindingPath bindingPath, UI5Model model
where model = bindingPath.getModel()
select bindingPath, model
