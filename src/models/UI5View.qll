import javascript
import UI5AMDModule
import semmle.javascript.frameworks.data.internal.ApiGraphModelsExtensions as ApiGraphModelsExtensions

/**
 * Utiility predicate returning
 * types that are supertype of the argument
 * ```
 *   data:["sap/m/InputBase", "sap/m/Input", ""]
 * ```
 */
bindingset[base]
private string getASuperType(string base) {
  result = base or ApiGraphModelsExtensions::typeModel(result, base, "")
}

/**
 * Utility predicate capturing
 * the binding path in the argument
 * ```
 *   value: "{Control>country}"
 * ```
 */
bindingset[property]
private string bindingPathCapture(string property) {
  property.matches("{%}") and
  exists(string pattern |
    // matches "Control>country"
    // TODO: save the Control name
    pattern = "(?:[^'\"\\}]+>)?([^'\"\\}]*)" and
    (
      // simple {Control>country}
      result = property.regexpCapture("(?s)\\{" + pattern + "\\}", 1)
      or
      // object {other:{foo:'bar'} path: 'Result>country'}
      result = property.regexpCapture("(?s)\\{[^\"]*path\\s*:\\s*'" + pattern + "'[^\"]*\\}", 1)
    )
  )
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
  /**
   * Returns the value of the binding path
   * as specified in the view
   */
  abstract string getPath();

  /**
   * Returns the absolute value of the binding path
   */
  abstract string getAbsolutePath();
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

class JsonBindingPath extends UI5BindingPath, JsonValue {
  string path;

  JsonBindingPath() { path = bindingPathCapture(this.getStringValue()) }

  override string getPath() { result = path }

  override string getAbsolutePath() {
    if path.matches("/%")
    then result = path
    else
      exists(JsonBindingPath composite_path |
        composite_path != this and
        composite_path = this.getParent+().(JsonObject).getPropValue("items") and
        result = composite_path.getAbsolutePath() + "/" + path
      )
  }

  override string toString() { result = path }
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

class XmlBindingPath extends UI5BindingPath, XmlAttribute {
  string path;

  XmlBindingPath() { path = bindingPathCapture(this.getValue()) }

  override string getPath() { result = path }

  override string getAbsolutePath() {
    if path.matches("/%")
    then result = path
    else
      exists(XmlBindingPath composite_path |
        composite_path = this.getElement().getParent+().(XmlElement).getAttribute("items") and
        result = composite_path.getAbsolutePath() + "/" + path
      )
  }

  override string toString() { result = path }

  override Location getLocation() { result = XmlAttribute.super.getLocation() }
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
