import javascript
import advanced_security.javascript.frameworks.ui5.UI5

from MethodCallNode getterOrSetter, string message
where
  exists(ControlReference controlReference, string propName |
    getterOrSetter = controlReference.getARead(propName) and
    message = "Getter of property " + propName
    or
    getterOrSetter = controlReference.getAWrite(propName) and
    message = "Setter of property " + propName
  )
select getterOrSetter, message
