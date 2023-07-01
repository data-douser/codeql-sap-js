import javascript
import DataFlow
import UI5AMDModule
import semmle.javascript.frameworks.data.internal.ApiGraphModelsExtensions as ApiGraphModelsExtensions

/**
 * Returns all the types that are supertype of base
 * ```
 * - addsTo:
 *     pack: codeql/javascript-all
 *     extensible: typeModel
 *   data:["sap/m/InputBase", "sap/m/Input", ""]
 * ```
 */
bindingset[base]
private string getASuperType(string base) {
  result = base or ApiGraphModelsExtensions::typeModel(result, base, "")
}

/**
 * Models a binding path
 * like the property value `{/input}` in the following example
 * ```
 * {
 * 	"Type": "sap.m.Input",
 * 	"value": "{/input}"
 * }
 * ```
 */
abstract class UI5BindingPath extends Locatable {
  abstract string getPathString();
}

/**
 * Models a UI5 View that might include
 * XSS sources and sinks in standard controls
 */
abstract class UI5View extends File {
  abstract string getControllerName();

  abstract UI5BindingPath getASource();

  abstract UI5BindingPath getAnHtmlISink();
}

private class JsonBindingPath extends UI5BindingPath, JsonValue {
  string value;

  JsonBindingPath() { value = this.getStringValue() and value.matches("{%}") }

  override string getPathString() { result = value }
}

class JsonView extends UI5View {
  JsonObject root;

  JsonView() {
    root.getPropStringValue("Type") = "sap.ui.core.mvc.JSONView" and
    this = root.getJsonFile()
  }

  override string getControllerName() { result = root.getPropStringValue("controllerName") }

  override JsonBindingPath getASource() {
    exists(JsonObject control, string type, string path, string property |
      root = control.getParent+() and
      type = control.getPropStringValue("Type").replaceAll(".", "/") and
      ApiGraphModelsExtensions::sourceModel(getASuperType(type), path, "remote") and
      property = path.regexpCapture("Instance\\.Member\\[([^\\]]+)\\]", 1) and
      result = control.getPropValue(property)
    )
  }

  override JsonBindingPath getAnHtmlISink() {
    exists(JsonObject control, string type, string path, string property |
      root = control.getParent+() and
      type = control.getPropStringValue("Type").replaceAll(".", "/") and
      ApiGraphModelsExtensions::sinkModel(getASuperType(type), path, "html-injection") and
      property = path.regexpCapture("Instance\\.Member\\[([^\\]]+)\\]", 1) and
      result = control.getPropValue(property)
    )
  }
}

private class XmlBindingPath extends UI5BindingPath, XmlAttribute {
  string value;

  XmlBindingPath() { value = this.getValue() and value.matches("{%}") }

  override string getPathString() { result = value }

  override string toString() { result = this.(XmlAttribute).toString() }

  override Location getLocation() { result = this.(XmlAttribute).getLocation() }
}

class XmlView extends UI5View {
  XmlElement root;

  XmlView() {
    root = this.(XmlFile).getARootElement() and
    root.getNamespace().getUri() = "sap.ui.core.mvc" and
    root.hasName("View")
  }

  override string getControllerName() { result = root.getAttributeValue("controllerName") }

  override XmlBindingPath getASource() {
    exists(XmlElement control, string type, string path, string property |
      this = control.getParent+() and
      type = control.getNamespace().getUri().replaceAll(".", "/") + "/" + control.getName() and
      ApiGraphModelsExtensions::sourceModel(getASuperType(type), path, "remote") and
      property = path.regexpCapture("Instance\\.Member\\[([^\\]]+)\\]", 1) and
      result = control.getAttribute(property)
    )
  }

  override XmlBindingPath getAnHtmlISink() {
    exists(XmlElement control, string type, string path, string property |
      this = control.getParent+() and
      type = control.getNamespace().getUri().replaceAll(".", "/") + "/" + control.getName() and
      ApiGraphModelsExtensions::sinkModel(getASuperType(type), path, "html-injection") and
      property = path.regexpCapture("Instance\\.Member\\[([^\\]]+)\\]", 1) and
      result = control.getAttribute(property)
    )
  }
}
