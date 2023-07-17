private import javascript
private import DataFlow
private import UI5::UI5
private import semmle.javascript.frameworks.data.internal.ApiGraphModelsExtensions as ApiGraphModelsExtensions

predicate builtInControl(XmlNamespace qualifiedTypeUri) {
  exists(string namespace |
    namespace =
      [
        "sap\\.m.*", // https://sapui5.hana.ondemand.com/#/api/sap.m: The main UI5 control library, with responsive controls that can be used in touch devices as well as desktop browsers.
        "sap\\.f.*", // https://sapui5.hana.ondemand.com/#/api/sap.f: SAPUI5 library with controls specialized for SAP Fiori apps.
        "sap\\.ui.*" // https://sapui5.hana.ondemand.com/#/api/sap.ui: The sap.ui namespace is the central OpenAjax compliant entry point for UI related JavaScript functionality provided by SAP.
      ]
  |
    qualifiedTypeUri.getUri().regexpMatch(namespace)
  )
}

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

  /**
   * Get the model declaration, which this data binding refers to, in a controller code.
   */
  UI5Model getModel() {
    exists(UI5View view |
      this.getLocation().getFile() = view and
      view.getController().getModel() = result
    )
  }
}

/**
 * Models a UI5 View that might include
 * XSS sources and sinks in standard controls
 */
abstract class UI5View extends File {
  abstract string getControllerName();

  /**
   * Get the Controller.extends(...) definition associated with this XML view.
   */
  CustomController getController() {
    // The controller name should match
    result.getName() = this.getControllerName() and
    // The View XML file and the controller are in a same project
    exists(Project project |
      project.isInThisProject(this) and project.isInThisProject(result.getFile())
    )
  }

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

  XmlElement getRoot() { result = root }

  /** Get the qualified type string, e.g. `sap.m.SearchField` */
  string getQualifiedType() { result = root.getNamespace().getUri() + "." + root.getName() }

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

  /**
   * Get the XML tags associated with UI5 Controls declared in this XML view.
   */
  XmlControl getXmlControl() {
    result =
      any(XmlElement element |
        // getAChild+ because "container controls" nest other controls inside them
        element = root.getAChild+() and
        // Either a builtin control provided by UI5
        (
          builtInControl(element.getNamespace())
          or
          // or a custom control with implementation code found in the project
          exists(CustomControl control, Project project |
            control.getName() = element.getNamespace().getUri() + "." + element.getName() and
            project.isInThisProject(control.getFile()) and
            project.isInThisProject(element.getFile())
          )
        )
      )
  }
}

class XmlControl extends XmlElement {
  XmlControl() { this.getParent+() = any(XmlView view) }

  /** Get the qualified type string, e.g. `sap.m.SearchField` */
  string getQualifiedType() { result = this.getNamespace().getUri() + "." + this.getName() }

  /** Get the JS Control definition if this is a custom control. */
  Extension getJSDefinition() {
    result = any(CustomControl control | control.getName() = this.getQualifiedType())
  }

  /** Get a reference to this control in the controller code. Currently supports only such references made through `byId`. */
  MethodCallNode getAReference() {
    result.getEnclosingFunction() = any(CustomController controller).getAMethod().asExpr() and
    result.getMethodName() = "byId" and
    result.getArgument(0).asExpr().(StringLiteral).getValue() = this.getAttributeValue("id")
  }

  CustomControl getDefinition() {
    result.getName() = this.getQualifiedType() and
    exists(Project project |
      project.isInThisProject(this.getFile()) and project.isInThisProject(result.getFile())
    )
  }

  predicate accessesModel(UI5Model model) {
    // Verify that the controller's model has the referenced property
    exists(XmlView view |
      // Both this control and the model belong to the same view
      this = view.getXmlControl() and
      model = view.getController().getModel() and
      model.getPathString() = this.getAnAttribute().(XmlBindingPath).getPath()
    )
    // TODO: Add case where modelName is present
  }

  predicate accessesModel(UI5Model model, XmlBindingPath bindingPath) {
    // Verify that the controller's model has the referenced property
    exists(XmlView view |
      // Both this control and the model belong to the same view
      this = view.getXmlControl() and
      model = view.getController().getModel() and
      model.getPathString() = bindingPath.getPath() and
      bindingPath.getPath() = this.getAnAttribute().(XmlBindingPath).getPath()
    )
    // TODO: Add case where modelName is present
  }

  predicate isXssSource() {
    exists(XmlView view, string type, string path, string property |
      view = this.getParent+() and
      type = this.getQualifiedType().replaceAll(".", "/") and
      ApiGraphModelsExtensions::sourceModel(getASuperType(type), path, "remote") and
      property = path.regexpCapture("Instance\\.Member\\[([^\\]]+)\\]", 1)
    )
  }

  predicate isXssSink() {
    exists(XmlView view, string type, string path, string property |
      view = this.getParent+() and
      type = this.getQualifiedType().replaceAll(".", "/") and
      ApiGraphModelsExtensions::sinkModel(getASuperType(type), path, "html-injection") and
      property = path.regexpCapture("Instance\\.Member\\[([^\\]]+)\\]", 1)
    )
  }
}
