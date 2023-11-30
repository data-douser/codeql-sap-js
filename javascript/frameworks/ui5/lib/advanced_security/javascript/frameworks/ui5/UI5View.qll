import javascript
import DataFlow
import advanced_security.javascript.frameworks.ui5.UI5::UI5
import semmle.javascript.frameworks.data.internal.ApiGraphModelsExtensions as ApiGraphModelsExtensions

/**
 * Gets the immediate supertype of a given type from the extensible predicate `typeModel` provided by
 * Model-as-Data Extension to the CodeQL runtime. If no type is defined as a supertype of a given one,
 * then this predicate is reflexive. e.g.
 * If there is a row such as below in the extension file:
 * ```yaml
 * ["sap/m/InputBase", "sap/m/Input", ""]
 * ```
 * Then it gets `"sap/m/InputBase"` when given `"sap/m/Input"`. However, if no such row is present, then
 * this predicate simply binds `result` to the given `"sap/m/Input"`.
 *
 * This predicate is good for modeling the object-oriented class hierarchy in UI5.
 */
bindingset[type]
private string getASuperType(string type) {
  result = type or ApiGraphModelsExtensions::typeModel(result, type, "")
}

/**
 * Holds if the given string contains a binding path. Also gets the
 * path string itself without the surrounding curly braces.
 * ```javascript
 * "{/property}" // Absolute path without a model name, gets `/property`
 * "{property1/property2}" // Relative path, gets `property1/property2`
 * "{model>property}" // Absolute path with a model name, gets `model>property`
 * "{ other: { foo: 'bar'}, path: 'model>property' }" // Gets the absolute path in the expression binding
 * "{.doSomething(${/input})}" // Gets the absolute path in parameter in the expression binding
 * ```
 */
bindingset[property]
string bindingPathCapture(string property) {
  exists(string pattern |
    // matches "model>property"
    pattern = "(?:[^'\"\\}]+>)?([^'\"\\}]*)" and
    (
      // {model>property}
      result = property.replaceAll(" ", "").regexpCapture("(?s)\\{" + pattern + "\\}", 1)
      or
      // { other: { foo: 'bar'}, path: 'model>property' }
      result =
        property
            .replaceAll(" ", "")
            .regexpCapture("(?s)\\{[^\"]*path:'" + pattern + "'[^\"]*\\}", 1)
      or
      // event handler with a simple parameter {.doSomething(${/input})}
      result =
        property
            .replaceAll(" ", "")
            .regexpCapture("(?s)\\.[\\w-]+\\(\\$\\{" + pattern + "\\}\\)", 1)
    )
  )
}

/**
 * Holds if the given string contains a binding path. Also gets the model name before the `>`
 * separator, if the given string has it.
 * ```javascript
 * "{model>property}"                                 // Gets `model`
 * "{ other: { foo: 'bar'}, path: 'model>property' }" // Gets `model` in the parameter
 * ```
 */
bindingset[property]
string modelNameCapture(string property) {
  exists(string pattern |
    // matches "model>property"
    pattern = "([^'\"\\}]+)>([^'\"\\}]*)"
  |
    (
      // {model>property}
      result = property.replaceAll(" ", "").regexpCapture("(?s)\\{" + pattern + "\\}", 1)
      or
      // { other: { foo: 'bar'}, path: 'model>property' }
      result =
        property
            .replaceAll(" ", "")
            .regexpCapture("(?s)\\{[^\"]*path:'" + pattern + "'[^\"]*\\}", 1)
      or
      // event handler with a simple parameter {.doSomething(${/input})}
      result =
        property
            .replaceAll(" ", "")
            .regexpCapture("(?s)\\.[\\w-]+\\(\\$\\{" + pattern + "\\}\\)", 1)
    )
  )
}

/**
 * A [binding path](https://sapui5.hana.ondemand.com/sdk/#/topic/2888af49635949eca14fa326d04833b9) that refers
 * to a piece of data in a model. It is found in a file which defines a view declaratively, using either XML,
 * HTML, JSON or JavaScript, and is a property of an XML/HTML element or a JSON/JavaScript object.
 *
 * Since these data cannot be recognized as `DataFlow::Node`s (with an exception of JS objects), a `UI5BindingPath`
 * is always represented by a `UI5BoundNode` to which this `UI5BindingPath` refers to.
 */
abstract class UI5BindingPath extends Locatable {
  /**
   * Gets the string value of this path, without the surrounding curly braces.
   */
  abstract string getPath();

  /**
   * Gets the string value of this path with the surrounding curly braces.
   */
  abstract string getLiteralRepr();

  /**
   * Resolve this path to an absolute one. It is reflexive for an already absolute path.
   */
  abstract string getAbsolutePath();

  /**
   * Gets the fully qualified name of the associated control.
   */
  abstract string getPropertyName();

  /**
   * Gets the fully qualified type of the associated control.
   */
  abstract string getControlQualifiedType();

  /**
   * Gets the name of the model if this binding path has one (before the ">" sign).
   */
  abstract string getModelName();

  /**
   * Gets the full import path of the associated control.
   */
  string getControlTypeName() { result = this.getControlQualifiedType().replaceAll(".", "/") }

  UI5View getView() { this.getFile() = result }

  /**
   * Gets the model, attached to a SapElement (either a control/view/controller), referred to by this binding path.
   */
  UI5Model getModel(SapElement sapElement) {
    exists(MethodCallNode setModelCall |
      setModelCall.getMethodName() = "setModel" and
      (
        sapElement.asDefinition().flowsTo(setModelCall.getReceiver()) or
        sapElement.asReference().flowsTo(setModelCall.getReceiver())
      )
    |
      /* Base case 1: the result is a named model and the names in the setModel call and in the binding path match up. */
      setModelCall.getArgument(1).getALocalSource().asExpr().(StringLiteral).getValue() =
        this.getModelName()
      or
      /* Base case 1: the result is a default (nameless) model and both the setModel call and the binding path lack a model name. */
      (
        not exists(setModelCall.getArgument(1)) and
        not exists(this.getModelName())
      ) and
      result = setModelCall.getArgument(0)
    )
    or
    /*
     * Recursive case: check the above two cases on the element's parent according to the hierarchy:
     *       control < view < controller < component.
     */

    result = this.getModel(sapElement.getParentElement())
  }

  /**
   * Gets the UI5BoundNode that represents this binding path.
   */
  Node getNode() {
    exists(Property p, JsonModel model |
      // The property bound to an UI5View source
      result.(DataFlow::PropWrite).getPropertyNameExpr() = p.getNameExpr() and
      this.getAbsolutePath() = model.getPathString(p) and
      // Restrict search inside the same webapp
      exists(WebApp webApp |
        webApp.getAResource() = this.getFile() and webApp.getAResource() = result.getFile()
      )
    )
    or
    result = this.getModel(_).(UI5ExternalModel)
  }

  /**
   * Holds if this binding path is absolute.
   * Reference: https://sapui5.hana.ondemand.com/sdk/#/topic/2888af49635949eca14fa326d04833b9
   */
  predicate isAbsolute() {
    exists(modelNameCapture(this.getLiteralRepr())) or this.getPath().charAt(0) = "/"
  }

  /**
   * Holds if this binding path is relative.
   * Reference: https://sapui5.hana.ondemand.com/sdk/#/topic/2888af49635949eca14fa326d04833b9
   */
  predicate isRelative() { not this.isAbsolute() }
}

abstract class UI5ControlProperty extends Locatable {
  abstract UI5Control getControl();

  abstract string getName();

  abstract string getValue();
}

class XmlControlProperty extends UI5ControlProperty instanceof XmlAttribute {
  XmlControlProperty() { this.getElement() = any(XmlControl control) }

  override string getName() { result = XmlAttribute.super.getName() }

  override string getValue() { result = XmlAttribute.super.getValue() }

  override UI5Control getControl() { result = XmlAttribute.super.getElement() }
}

/**
 * Models a UI5 View that might include
 * XSS sources and sinks in standard controls
 */
abstract class UI5View extends File {
  abstract string getControllerName();

  /**
   * Get the `Controller.extends(...)` definition associated with this View.
   */
  CustomController getController() {
    // The controller name should match
    result.getName() = this.getControllerName() and
    // The View and the Controller are in a same webapp
    exists(WebApp webApp |
      webApp.getAResource() = this and webApp.getAResource() = result.getFile()
    )
  }

  abstract UI5BindingPath getASource();

  abstract UI5BindingPath getAnHtmlISink();
}

/**
 * A UI5BindingPath found in a JSON View.
 */
class JsonBindingPath extends UI5BindingPath, JsonValue {
  string path;

  JsonBindingPath() { path = bindingPathCapture(this.getStringValue()) }

  override string toString() {
    result = "\"" + this.getPropertyName() + "\": \"" + this.getStringValue() + "\""
  }

  override string getLiteralRepr() { result = this.getStringValue() }

  override string getPath() { result = path }

  override string getAbsolutePath() {
    if path.matches("/%")
    then result = path
    else
      exists(JsonBindingPath pathPrefix |
        pathPrefix = this.getParent+().(JsonObject).getPropValue("items") and
        pathPrefix != this
      |
        result = pathPrefix.getAbsolutePath() + "/" + path
      )
  }

  override string getPropertyName() { this = any(JsonValue v).getPropValue(result) }

  override string getControlQualifiedType() {
    exists(JsonObject control |
      this = control.getPropValue(this.getPropertyName()) and
      result = control.getPropStringValue("Type")
    )
  }

  override string getModelName() { result = modelNameCapture(this.getStringValue()) }
}

class JsView extends UI5View {
  /* sap.ui.jsview("...", ) { ... } */
  MethodCallNode rootJsViewCall;

  JsView() {
    exists(TopLevel toplevel, Stmt stmt |
      toplevel = unique(TopLevel t | t = this.getATopLevel()) and
      stmt = unique(Stmt s | s = toplevel.getAChildStmt())
    |
      rootJsViewCall.asExpr() = stmt.getAChildExpr() and
      rootJsViewCall.getReceiver() = DataFlow::globalVarRef("sap").getAPropertyReference("ui") and
      rootJsViewCall.getMethodName() = "jsview"
    )
  }

  override string getControllerName() {
    exists(FunctionNode function |
      function =
        rootJsViewCall
            .getArgument(1)
            .(ObjectLiteralNode)
            .getAPropertySource("getControllerName")
            .(FunctionNode) and
      result = function.getReturnNode().getALocalSource().asExpr().(StringLiteral).getValue()
    )
  }

  override JsBindingPath getASource() {
    exists(ObjectExpr control, string type, string path, string property |
      this = control.getFile() and
      type = result.getControlTypeName() and
      ApiGraphModelsExtensions::sourceModel(getASuperType(type), path, "remote") and
      property = path.replaceAll(" ", "").regexpCapture("Member\\[([^\\]]+)\\]", 1) and
      result = control.getPropertyByName(property)
    )
  }

  override JsBindingPath getAnHtmlISink() {
    exists(ObjectExpr control, string type, string path, string property |
      this = control.getFile() and
      type = result.getControlTypeName() and
      ApiGraphModelsExtensions::sinkModel(getASuperType(type), path, "ui5-html-injection") and
      property = path.replaceAll(" ", "").regexpCapture("Member\\[([^\\]]+)\\]", 1) and
      result = control.getPropertyByName(property)
    )
  }
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
      type = result.getControlTypeName() and
      ApiGraphModelsExtensions::sourceModel(getASuperType(type), path, "remote") and
      property = path.replaceAll(" ", "").regexpCapture("Member\\[([^\\]]+)\\]", 1) and
      result = control.getPropValue(property)
    )
  }

  override JsonBindingPath getAnHtmlISink() {
    exists(JsonObject control, string type, string path, string property |
      root = control.getParent+() and
      type = result.getControlTypeName() and
      ApiGraphModelsExtensions::sinkModel(getASuperType(type), path, "ui5-html-injection") and
      property = path.replaceAll(" ", "").regexpCapture("Member\\[([^\\]]+)\\]", 1) and
      result = control.getPropValue(property)
    )
  }
}

/**
 * A UI5BindingPath found in a JavaScript View.
 */
class JsBindingPath extends UI5BindingPath, Property {
  string path;

  JsBindingPath() {
    path = bindingPathCapture(this.getInit().getStringValue()) and
    this.(Property).getFile() instanceof JsView
  }

  override string getLiteralRepr() { result = this.getInit().getStringValue() }

  private string dotExprToStringInner(Expr expr) {
    if not expr instanceof DotExpr
    then result = expr.toString()
    else
      exists(Expr subexpr, string propName |
        expr.(DotExpr).accesses(subexpr, propName) and
        result = dotExprToStringInner(subexpr) + "." + propName
      )
  }

  /** `a.b.c.d.e.f.g(...)` => `"a.b.c.d.e.f.g"` */
  private string dotExprToString(DotExpr dot) { result = dotExprToStringInner(dot) }

  /* `new sap.m.Input({...})` => `"sap.m.Input"` */
  override string getControlQualifiedType() {
    result =
      dotExprToString(this.getInit().(StringLiteral).getParent+().(NewExpr).getCallee().(DotExpr))
  }

  override string getAbsolutePath() { result = path /* ??? */ }

  override string getPath() { result = path }

  override string getPropertyName() { result = this.getName() }

  override string getModelName() { result = modelNameCapture(this.getInit().getStringValue()) }
}

/**
 * A UI5BindingPath found in an HTML View.
 */
class HtmlBindingPath extends UI5BindingPath, HTML::Attribute {
  string path;

  HtmlBindingPath() { path = bindingPathCapture(this.getValue()) }

  override string getPath() { result = path }

  override string getLiteralRepr() { result = this.getValue() }

  override string getAbsolutePath() {
    if path.matches("/%")
    then result = path
    else
      exists(HtmlBindingPath pathPrefix |
        pathPrefix != this and
        pathPrefix = this.getElement().getParent+().(HTML::Element).getAttributeByName("items") and
        result = pathPrefix.getAbsolutePath() + "/" + path
      )
  }

  override string getPropertyName() { this = any(HTML::Element v).getAttributeByName(result) }

  override string getControlQualifiedType() {
    exists(HTML::Element control |
      this = control.getAttributeByName(this.getPropertyName()) and
      result = control.getAttributeByName("data-sap-ui-type").getValue()
    )
  }

  override string getModelName() { result = modelNameCapture(this.getValue()) }
}

class HtmlView extends UI5View, HTML::HtmlFile {
  HTML::Element root;

  HtmlView() {
    this = root.getFile() and
    this.getBaseName().toLowerCase().matches("%.view.html") and
    root.isTopLevel()
  }

  override string getControllerName() {
    result = root.getAttributeByName("data-controller-name").getValue()
  }

  override HtmlBindingPath getASource() {
    exists(HTML::Element control, string type, string path, string property |
      this = control.getFile() and
      type = result.getControlTypeName() and
      ApiGraphModelsExtensions::sourceModel(getASuperType(type), path, "remote") and
      property = path.replaceAll(" ", "").regexpCapture("Member\\[([^\\]]+)\\]", 1) and
      result = control.getAttributeByName("data-" + property)
    )
  }

  override HtmlBindingPath getAnHtmlISink() {
    exists(HTML::Element control, string type, string path, string property |
      this = control.getFile() and
      type = result.getControlTypeName() and
      ApiGraphModelsExtensions::sinkModel(getASuperType(type), path, "ui5-html-injection") and
      property = path.replaceAll(" ", "").regexpCapture("Member\\[([^\\]]+)\\]", 1) and
      result = control.getAttributeByName("data-" + property)
    )
  }
}

/**
 * A UI5BindingPath found in an XML View.
 */
class XmlBindingPath extends UI5BindingPath instanceof XmlAttribute {
  string path;

  XmlBindingPath() { path = bindingPathCapture(this.getValue()) }

  override string getLiteralRepr() { result = this.(XmlAttribute).getValue() }

  override Location getLocation() { result = XmlAttribute.super.getLocation() }

  override string getPath() { result = path }

  override string getAbsolutePath() {
    if path.matches("/%")
    then result = path
    else
      exists(XmlBindingPath pathPrefix |
        pathPrefix =
          this.(XmlAttribute).getElement().getParent+().(XmlElement).getAttribute("items") and
        result = pathPrefix.getAbsolutePath() + "/" + path
      )
  }

  override string getPropertyName() { result = this.(XmlAttribute).getName() }

  override string getControlQualifiedType() {
    exists(XmlElement control |
      control = this.(XmlAttribute).getElement() and
      this = control.getAttribute(this.getPropertyName()) and
      result = control.getNamespace().getUri() + "." + control.getName()
    )
  }

  UI5Control getControl() {
    this = result.(XmlElement).getAttribute(this.getPropertyName()) and
    result = XmlAttribute.super.getElement()
  }

  override string getModelName() { result = modelNameCapture(this.(XmlAttribute).getValue()) }
}

class XmlRootElement extends XmlElement {
  XmlRootElement() { any(XmlFile f).getARootElement() = this }

  /**
   * Returns a XML namespace declaration scoped to the element.
   *
   * The predicate relies on location information to determine the scope of the namespace declaration.
   * A XML element with the same starting line and column, but a larger ending line and column is considered the
   * scope of the namespace declaration.
   */
  XmlNamespace getANamespaceDeclaration() {
    exists(Location elemLoc, Location nsLoc |
      elemLoc = this.getLocation() and
      nsLoc = result.getLocation()
    |
      elemLoc.getStartLine() = nsLoc.getStartLine() and
      elemLoc.getStartColumn() = nsLoc.getStartColumn() and
      (
        elemLoc.getEndLine() > nsLoc.getEndLine()
        or
        elemLoc.getEndLine() = nsLoc.getEndLine() and
        elemLoc.getEndColumn() > nsLoc.getEndColumn()
      )
    )
  }
}

class XmlView extends UI5View, XmlFile {
  XmlRootElement root;

  XmlView() {
    root = this.getARootElement() and
    (
      root.getNamespace().getUri() = "sap.ui.core.mvc"
      or
      root.getNamespace().getUri() = "sap.ui.core" and
      root.getANamespaceDeclaration().getUri() = "sap.ui.core.mvc"
    ) and
    root.hasName("View")
  }

  /** Get the qualified type string, e.g. `sap.m.SearchField` */
  string getQualifiedType() { result = root.getNamespace().getUri() + "." + root.getName() }

  override string getControllerName() { result = root.getAttributeValue("controllerName") }

  override XmlBindingPath getASource() {
    exists(XmlElement control, string type, string path, string property |
      this = control.getFile() and
      type = result.getControlTypeName() and
      ApiGraphModelsExtensions::sourceModel(getASuperType(type), path, "remote") and
      property = path.replaceAll(" ", "").regexpCapture("Member\\[([^\\]]+)\\]", 1) and
      result = control.getAttribute(property)
    )
  }

  override XmlBindingPath getAnHtmlISink() {
    exists(XmlElement control, string type, string path, string property |
      this = control.getFile() and
      type = result.getControlTypeName() and
      ApiGraphModelsExtensions::sinkModel(getASuperType(type), path, "ui5-html-injection") and
      property = path.replaceAll(" ", "").regexpCapture("Member\\[([^\\]]+)\\]", 1) and
      result = control.getAttribute(property)
    )
  }

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
          // or a custom control with implementation code found in the webapp
          exists(CustomControl control |
            control.getName() = element.getNamespace().getUri() + "." + element.getName() and
            exists(WebApp webApp |
              webApp.getAResource() = control.getFile() and
              webApp.getAResource() = element.getFile()
            )
          )
        )
      )
  }
}

abstract class UI5Control extends Locatable {
  /**
   * Gets the qualified type string, e.g. `sap.m.SearchField`.
   */
  abstract string getQualifiedType();

  /**
   * Gets the `id` property of this control.
   */
  string getId() { result = this.getProperty("id").getValue() }

  /**
   * Gets the qualified type name, e.g. `sap/m/SearchField`.
   */
  string getImportPath() { result = this.getQualifiedType().replaceAll(".", "/") }

  /**
   * Gets the definition of this control if this is a custom one.
   */
  abstract Extension getDefinition();

  /**
   * Gets a reference to this control in the controller code. Currently supports only such references made through `byId`.
   */
  ControlReference getAReference() {
    result.getEnclosingFunction() = any(CustomController controller).getAMethod().asExpr() and
    result.getArgument(0).asExpr().(StringLiteral).getValue() = this.getProperty("id").getValue()
  }

  /** Gets a property of this control having the name. */
  abstract UI5ControlProperty getProperty(string propName);

  bindingset[propName]
  abstract MethodCallNode getARead(string propName);

  bindingset[propName]
  abstract MethodCallNode getAWrite(string propName);

  /** Holds if this control reads from or writes to a model. */
  abstract predicate accessesModel(UI5Model model);

  /** Holds if this control reads from or writes to a model with regards to a binding path. */
  abstract predicate accessesModel(UI5Model model, UI5BindingPath bindingPath);

  /** Get the view that this control is part of. */
  abstract UI5View getView();

  /** Get the controller that manages this control. */
  CustomController getController() { result = this.getView().getController() }
}

class XmlControl extends UI5Control instanceof XmlElement {
  XmlControl() { this.getParent+() = any(XmlView view) }

  /** Get the qualified type string, e.g. `sap.m.SearchField` */
  override string getQualifiedType() {
    result = XmlElement.super.getNamespace().getUri() + "." + XmlElement.super.getName()
  }

  override Location getLocation() { result = this.(XmlElement).getLocation() }

  override XmlFile getFile() { result = XmlElement.super.getFile() }

  override UI5ControlProperty getProperty(string name) {
    result = this.(XmlElement).getAttribute(name)
  }

  override CustomControl getDefinition() {
    result.getName() = this.getQualifiedType() and
    exists(WebApp webApp |
      webApp.getAResource() = this.getFile() and webApp.getAResource() = result.getFile()
    )
  }

  bindingset[propName]
  override MethodCallNode getARead(string propName) {
    // TODO: in same view
    exists(WebApp webApp |
      webApp.getAResource() = this.getFile() and webApp.getAResource() = result.getFile()
    ) and
    result.getMethodName() = "get" + capitalize(propName)
  }

  bindingset[propName]
  override MethodCallNode getAWrite(string propName) {
    // TODO: in same view
    exists(WebApp webApp |
      webApp.getAResource() = this.getFile() and webApp.getAResource() = result.getFile()
    ) and
    result.getMethodName() = "set" + capitalize(propName)
  }

  override predicate accessesModel(UI5Model model) {
    // Verify that the controller's model has the referenced property
    exists(XmlView view |
      // Both this control and the model belong to the same view
      this = view.getXmlControl() and
      model = view.getController().getModel() and
      model.(UI5InternalModel).getPathString() =
        XmlElement.super.getAnAttribute().(XmlBindingPath).getPath()
    )
    // TODO: Add case where modelName is present
  }

  override predicate accessesModel(UI5Model model, UI5BindingPath bindingPath) {
    // Verify that the controller's model has the referenced property
    exists(XmlView view |
      // Both this control and the model belong to the same view
      this = view.getXmlControl() and
      model = view.getController().getModel() and
      model.(UI5InternalModel).getPathString() = bindingPath.getPath() and
      bindingPath.getPath() = XmlElement.super.getAnAttribute().(XmlBindingPath).getPath()
    )
    // TODO: Add case where modelName is present
  }

  override UI5View getView() { result = XmlElement.super.getParent+() }

  override string toString() { result = XmlElement.super.toString() }
}

/**
 *  Utility predicate capturing the handler name.
 */
bindingset[notation]
private string handlerNotationCaptureName(string notation) {
  result =
    notation.replaceAll(" ", "").regexpCapture("\\.([\\w-]+)(?:\\([^)]*\\$(\\{[^}]+}).*)?", 1)
}

/**
 * A function mentioned in a property of a UI5Control, usually an event handler.
 *
 * e.g. The function referred to by `doSomething()` as in `<Button press=".doSomething"/>`.
 */
class UI5Handler extends FunctionNode {
  UI5Control control;

  UI5Handler() {
    this = control.getController().getAMethod() and
    handlerNotationCaptureName(control.getProperty(_).getValue()) = this.getName()
  }

  UI5BindingPath getBindingPath() {
    exists(string propName |
      handlerNotationCaptureName(control.getProperty(propName).getValue()) = this.getName() and
      //result.control
      result = control.getProperty(result.getPropertyName())
    )
  }

  UI5Control getControl() { result = control }
}

/**
 * Models controller references in event handlers as types
 */
class ControlTypeInHandlerModel extends ModelInput::TypeModel {
  // TODO (see https://github.com/github/codeql/pull/14120)
  // override predicate isTypeUsed(string type) { type = any(UI5Control c).getImportPath() }
  override DataFlow::CallNode getASource(string type) {
    // oEvent.getSource() is of the type of the Control calling the handler
    exists(UI5Handler h |
      type = h.getControl().getImportPath() and
      result.getCalleeName() = "getSource" and
      result.getReceiver().getALocalSource() = h.getParameter(0)
    )
    or
    // this.getView().byId("id") is of the type of the Control with id="id"
    exists(UI5Control c |
      type = c.getImportPath() and
      result = c.getAReference()
    )
  }
}

/**
 * A workaround for the interfearence of pruning with TypeModel
 * TODO remove after https://github.com/github/codeql/pull/14120
 */
class DisablePruning extends ModelInput::TypeModelCsv {
  override predicate row(string row) {
    row = any(UI5Control c).getImportPath() + ";global;DummyAccessPathForPruning"
  }
}
