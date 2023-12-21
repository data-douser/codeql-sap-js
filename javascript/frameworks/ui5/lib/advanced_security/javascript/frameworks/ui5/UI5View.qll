import javascript
import DataFlow
import advanced_security.javascript.frameworks.ui5.UI5
import advanced_security.javascript.frameworks.ui5.dataflow.DataFlow
import semmle.javascript.frameworks.data.internal.ApiGraphModelsExtensions as ApiGraphModelsExtensions
import advanced_security.javascript.frameworks.ui5.Bindings

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
string getASuperType(string type) {
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
abstract class UI5BindingPath extends BindingPath {
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
   * Gets the full import path of the associated control.
   */
  string getControlTypeName() { result = this.getControlQualifiedType().replaceAll(".", "/") }

  /**
   * NOTE:
   * - [[Declarative (inside data format): path --getFile--> view]] --getController--> controller --getModel--> model.
   * - Procedural (inside JS source code): [[path --(getting the handler it's inside and getting the owner controller of the handler )--> controller --getView--> view]].
   */
  UI5View getView() {
    /* 1. Declarative, inside a certain data format. */
    this.getLocation().getFile() = result
    or
    /* 2. Procedural, inside a body of a controller handler. */
    exists(CustomController controller |
      controller.getFile() = this.getLocation().getFile() and
      controller.getView() = result
    )
  }

  /**
   * Gets the UI5Control using this UI5BindingPath.
   */
  UI5Control getControlDeclaration() { none() }

  /**
   * Gets the model, attached to either a control or a view, that this binding path refers to.
   */
  UI5Model getModel() {
    (
      /* 1. The result is a named model and the names in the controlSetModel call and in the binding path match up, but the viewSetModelCall isn't the case. */
      exists(MethodCallNode controlSetModelCall |
        controlSetModelCall.getMethodName() = "setModel" and
        this.getControlDeclaration().getAReference().flowsTo(controlSetModelCall.getReceiver()) and
        controlSetModelCall.getArgument(1).getALocalSource().asExpr().(StringLiteral).getValue() =
          this.getModelName() and
        result.flowsTo(controlSetModelCall.getArgument(0))
      )
      or
      /* 2. The result is a default (nameless) model and both the controlSetModel call and the binding path lack a model name, but the viewSetModeCall isn't the case. */
      exists(MethodCallNode controlSetModelCall |
        controlSetModelCall.getMethodName() = "setModel" and
        this.getControlDeclaration().getAReference().flowsTo(controlSetModelCall.getReceiver()) and
        not exists(controlSetModelCall.getArgument(1)) and
        not exists(this.getModelName()) and
        result.flowsTo(controlSetModelCall.getArgument(0))
      )
      or
      /* 3. There is no call to `setModel` on a control reference that sets a named model, so we look if the view reference has one. */
      exists(MethodCallNode viewSetModelCall |
        viewSetModelCall.getMethodName() = "setModel" and
        this.getView().getController().getAViewReference().flowsTo(viewSetModelCall.getReceiver()) and
        viewSetModelCall.getArgument(1).getALocalSource().asExpr().(StringLiteral).getValue() =
          this.getModelName() and
        result.flowsTo(viewSetModelCall.getArgument(0))
      ) and
      not exists(MethodCallNode controlSetModelCall |
        controlSetModelCall.getMethodName() = "setModel" and
        this.getControlDeclaration().getAReference().flowsTo(controlSetModelCall.getReceiver()) and
        controlSetModelCall.getArgument(1).getALocalSource().asExpr().(StringLiteral).getValue() =
          this.getModelName()
      )
      or
      /* 4. There is no call to `setModel` on a control reference that set an unnamed model, so we look if the view reference has one. */
      exists(MethodCallNode viewSetModelCall |
        viewSetModelCall.getMethodName() = "setModel" and
        this.getView().getController().getAViewReference().flowsTo(viewSetModelCall.getReceiver()) and
        not exists(viewSetModelCall.getArgument(1)) and
        not exists(this.getModelName()) and
        result.flowsTo(viewSetModelCall.getArgument(0))
      ) and
      not exists(MethodCallNode controlSetModelCall |
        controlSetModelCall.getMethodName() = "setModel" and
        this.getControlDeclaration().getAReference().flowsTo(controlSetModelCall.getReceiver()) and
        not exists(controlSetModelCall.getArgument(1)) and
        not exists(this.getModelName())
      )
    )
    // and
    // /* This binding path and the resulting model should live inside the same webapp */
    // exists(WebApp webApp |
    //   webApp.getAResource() = this.getFile() and webApp.getAResource() = result.getFile()
    // )
  }

  /**
   * Gets the UI5BoundNode that represents this binding path.
   */
  Node getNode() {
    exists(Property p, JsonModel model |
      /* Get the property bound to this binding path. */
      result.(DataFlow::PropWrite).getPropertyNameExpr() = p.getNameExpr() and
      this.getAbsolutePath() = model.getPathString(p) and
      /* Restrict search inside the same webapp. */
      exists(WebApp webApp |
        webApp.getAResource() = this.getLocation().getFile() and
        webApp.getAResource() = result.getFile()
      )
    )
    or
    result = this.getModel().(UI5ExternalModel)
  }
}

class XmlControlProperty extends XmlAttribute {
  XmlControlProperty() { exists(UI5Control control | this.getElement() = control.asXmlControl()) }

  override string getName() { result = XmlAttribute.super.getName() }

  override string getValue() { result = XmlAttribute.super.getValue() }
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
    /* The controller name should match between the view and the controller definition. */
    result.getName() = this.getControllerName() and
    /* The View and the Controller are in a same webapp. */
    exists(WebApp webApp |
      webApp.getAResource() = this and webApp.getAResource() = result.getFile()
    )
  }

  abstract UI5BindingPath getASource();

  abstract UI5BindingPath getAnHtmlISink();
}

JsonBindingPath getJsonItemsBinding(JsonBindingPath bindingPath) {
  exists(Binding itemsBinding |
    itemsBinding.getBindingTarget().asJsonObject("items") =
      bindingPath.getBindingTarget().getParent+() and
    result = itemsBinding.getBindingPath() and
    result != bindingPath // exclude ourselves
  ) and
  not exists(bindingPath.getModelName())
}

/**
 * A UI5BindingPath found in a JSON View.
 */
class JsonBindingPath extends UI5BindingPath {
  string boundPropertyName;
  Binding binding;
  JsonObject bindingTarget;

  JsonBindingPath() {
    bindingTarget = binding.getBindingTarget().asJsonObject(boundPropertyName) and
    binding.getBindingPath() = this
  }

  override string toString() {
    result =
      "\"" + boundPropertyName + "\": \"" + bindingTarget.getPropStringValue(boundPropertyName) +
        "\""
  }

  override string getLiteralRepr() { result = bindingTarget.getPropStringValue(boundPropertyName) }

  override string getPath() { result = this.asString() }

  override string getAbsolutePath() {
    if this.isAbsolute()
    then result = this.asString()
    else
      if exists(getJsonItemsBinding(this))
      then result = getJsonItemsBinding(this).getAbsolutePath() + "/" + this.asString()
      else result = this.asString()
  }

  override string getPropertyName() { result = boundPropertyName }

  override string getControlQualifiedType() { result = bindingTarget.getPropStringValue("Type") }

  JsonObject getBindingTarget() { result = bindingTarget }
}

// class JsView extends UI5View {
//   /* sap.ui.jsview("...", ) { ... } */
//   MethodCallNode rootJsViewCall;
//   JsView() {
//     exists(TopLevel toplevel, Stmt stmt |
//       toplevel = unique(TopLevel t | t = this.getATopLevel()) and
//       stmt = unique(Stmt s | s = toplevel.getAChildStmt())
//     |
//       rootJsViewCall.asExpr() = stmt.getAChildExpr() and
//       rootJsViewCall.getReceiver() = DataFlow::globalVarRef("sap").getAPropertyReference("ui") and
//       rootJsViewCall.getMethodName() = "jsview"
//     )
//   }
//   override string getControllerName() {
//     exists(FunctionNode function |
//       function =
//         rootJsViewCall
//             .getArgument(1)
//             .(ObjectLiteralNode)
//             .getAPropertySource("getControllerName")
//             .(FunctionNode) and
//       result = function.getReturnNode().getALocalSource().asExpr().(StringLiteral).getValue()
//     )
//   }
//   override JsViewBindingPath getASource() {
//     exists(ObjectExpr control, string type, string path, string property |
//       this = control.getFile() and
//       type = result.getControlTypeName() and
//       ApiGraphModelsExtensions::sourceModel(getASuperType(type), path, "remote") and
//       property = path.replaceAll(" ", "").regexpCapture("Member\\[([^\\]]+)\\]", 1) and
//       result = control.getPropertyByName(property)
//     )
//   }
//   override JsViewBindingPath getAnHtmlISink() {
//     exists(ObjectExpr control, string type, string path, string property |
//       this = control.getFile() and
//       type = result.getControlTypeName() and
//       ApiGraphModelsExtensions::sinkModel(getASuperType(type), path, "ui5-html-injection") and
//       property = path.replaceAll(" ", "").regexpCapture("Member\\[([^\\]]+)\\]", 1) and
//       result = control.getPropertyByName(property)
//     )
//   }
// }
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
      result.getBindingTarget() = control
    )
  }

  override JsonBindingPath getAnHtmlISink() {
    exists(JsonObject control, string type, string path, string property |
      root = control.getParent+() and
      type = result.getControlTypeName() and
      ApiGraphModelsExtensions::sinkModel(getASuperType(type), path, "ui5-html-injection") and
      property = path.replaceAll(" ", "").regexpCapture("Member\\[([^\\]]+)\\]", 1) and
      result.getBindingTarget() = control
    )
  }
}

// class JsViewBindingPath extends UI5BindingPath {
//   DataFlow::PropRef bindingTarget;
//   JsViewBindingPath() {
//     // this = binding.getBindingTarget().asXmlAttribute() and
//     // binding.getBindingPath().asString() = path and
//     // exists(binding.getBindingPath())
//     this.getBinding().getBindingTarget().asDataFlowNode() = bindingTarget and
//     bindingTarget.getFile() instanceof JsView
//   }
//   override string getLiteralRepr() { result = .getInit().getStringValue() }
//   /* `new sap.m.Input({...})` => `"sap.m.Input"` */
//   override string getControlQualifiedType() {
//     result =
//       this.getInit().(StringLiteral).getParent+().(NewExpr).getCallee().(DotExpr).getQualifiedName()
//   }
//   override string getAbsolutePath() { result = path /* ??? */ }
//   override string getPath() { result = path }
//   override string getPropertyName() { result = this.getName() }
//   override string getModelName() { result = modelNameCapture(this.getInit().getStringValue()) }
//   override UI5Control getControlDeclaration() {
//     /* TODO */
//     none()
//   }
// }
HtmlBindingPath getHtmlItemsBinding(HtmlBindingPath bindingPath) {
  exists(Binding itemsBinding |
    result != bindingPath and
    itemsBinding.getBindingTarget().asXmlAttribute().getName() = "items" and
    bindingPath.getBindingTarget().getElement().getParent+().(HTML::Element).getAnAttribute() =
      itemsBinding.getBindingTarget().asXmlAttribute() and
    result = itemsBinding.getBindingPath()
  ) and
  not exists(bindingPath.getModelName())
}

/**
 * A UI5BindingPath found in an HTML View.
 */
class HtmlBindingPath extends UI5BindingPath {
  HTML::Attribute bindingTarget;
  Binding binding;

  HtmlBindingPath() {
    bindingTarget = binding.getBindingTarget().asXmlAttribute() and
    binding.getBindingPath() = this
  }

  override string getPath() { result = this.asString() }

  override string getLiteralRepr() { result = bindingTarget.getValue() }

  override string getAbsolutePath() {
    if this.isAbsolute()
    then result = this.asString()
    else
      if exists(getHtmlItemsBinding(this))
      then result = getHtmlItemsBinding(this).getPath() + "/" + this.getPath()
      else result = this.asString()
  }

  override string getPropertyName() { result = bindingTarget.getName() }

  override string getControlQualifiedType() {
    exists(HTML::Element control |
      bindingTarget = control.getAttributeByName(this.getPropertyName()) and
      result = control.getAttributeByName("data-sap-ui-type").getValue()
    )
  }

  HTML::Attribute getBindingTarget() { result = bindingTarget }

  override string toString() { result = bindingTarget.toString() }
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
      result.getBindingTarget() = control.getAttributeByName("data-" + property)
    )
  }

  override HtmlBindingPath getAnHtmlISink() {
    exists(HTML::Element control, string type, string path, string property |
      this = control.getFile() and
      type = result.getControlTypeName() and
      ApiGraphModelsExtensions::sinkModel(getASuperType(type), path, "ui5-html-injection") and
      property = path.replaceAll(" ", "").regexpCapture("Member\\[([^\\]]+)\\]", 1) and
      result.getBindingTarget() = control.getAttributeByName("data-" + property)
    )
  }
}

XmlBindingPath getXmlItemsBinding(XmlBindingPath bindingPath) {
  exists(Binding itemsBinding |
    result != bindingPath and
    itemsBinding.getBindingTarget().asXmlAttribute().getName() = "items" and
    bindingPath.getBindingTarget().getElement().getParent+().(XmlElement).getAnAttribute() =
      itemsBinding.getBindingTarget().asXmlAttribute() and
    result = itemsBinding.getBindingPath()
  ) and
  not exists(bindingPath.getModelName())
}

/**
 * A UI5BindingPath found in an XML View.
 */
class XmlBindingPath extends UI5BindingPath {
  Binding binding;
  XmlAttribute bindingTarget;

  XmlBindingPath() {
    bindingTarget = binding.getBindingTarget().asXmlAttribute() and
    binding.getBindingPath() = this
  }

  /* corresponds to BindingPath.asString() */
  override string getLiteralRepr() { result = bindingTarget.getValue() }

  override string getPath() { result = this.asString() }

  /**
   * TODO: take into consideration bindElement() method call
   * e.g.
   */
  override string getAbsolutePath() {
    if this.isAbsolute()
    then result = this.asString()
    else
      if exists(getXmlItemsBinding(this))
      then result = getXmlItemsBinding(this).getPath() + "/" + this.getPath()
      else result = this.asString()
  }

  override string getPropertyName() { result = bindingTarget.getName() }

  override string getControlQualifiedType() {
    exists(XmlElement control |
      control = bindingTarget.getElement() and
      result = control.getNamespace().getUri() + "." + control.getName()
    )
  }

  override UI5Control getControlDeclaration() { result.asXmlControl() = bindingTarget.getElement() }

  override string getModelName() { result = binding.getBindingPath().getModelName() }

  override string toString() { result = bindingTarget.toString() }

  XmlAttribute getBindingTarget() { result = bindingTarget }
}

class XmlRootElement extends XmlElement {
  XmlRootElement() { any(XmlFile f).getARootElement() = this }

  /**
   * Returns a XML namespace declaration scoped to the element.
   *
   * The predicate relies on location information to determine the scope of the namespace declaration.
   * A XML element with the same starting line and column, but a larger ending line and column is
   * considered the scope of the namespace declaration.
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
      result.getBindingTarget() = control.getAttribute(property)
    )
  }

  override XmlBindingPath getAnHtmlISink() {
    exists(XmlElement control, string type, string path, string property |
      this = control.getFile() and
      type = result.getControlTypeName() and
      ApiGraphModelsExtensions::sinkModel(getASuperType(type), path, "ui5-html-injection") and
      property = path.replaceAll(" ", "").regexpCapture("Member\\[([^\\]]+)\\]", 1) and
      result.getBindingTarget() = control.getAttribute(property) and
      /* If the control is an `sap.ui.core.HTML` then the control should be missing the `sanitizeContent` attribute */
      (
        getASuperType(type) = "HTMLControl"
        implies
        (
          not exists(control.getAttribute("sanitizeContent")) or
          control.getAttribute("sanitizeContent").getValue() = "false"
        )
      )
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
  UI5Control getXmlControl() {
    result.asXmlControl() =
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

newtype TUI5Control = TXmlControl(XmlElement element)

class UI5Control extends TUI5Control {
  XmlElement asXmlControl() { this = TXmlControl(result) }

  string toString() { result = this.asXmlControl().toString() }

  /**
   * Gets the qualified type string, e.g. `sap.m.SearchField`.
   */
  string getQualifiedType() {
    exists(XmlElement element | element = this.asXmlControl() |
      result = element.getNamespace().getUri() + "." + element.getName()
    )
  }

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
  CustomControl getDefinition() {
    result.getName() = this.getQualifiedType() and
    exists(WebApp webApp |
      webApp.getAResource() = this.asXmlControl().getFile() and
      webApp.getAResource() = result.getFile()
    )
  }

  /**
   * Gets a reference to this control in the controller code. Currently supports only such references made through `byId`.
   */
  ControlReference getAReference() {
    result.getEnclosingFunction() = any(CustomController controller).getAMethod().asExpr() and
    result.getArgument(0).asExpr().(StringLiteral).getValue() = this.getProperty("id").getValue()
  }

  /** Gets a property of this control having the name. */
  UI5ControlProperty getProperty(string propName) {
    result.asXmlControlProperty() = this.asXmlControl().getAttribute(propName)
  }

  UI5ControlProperty getAProperty() { result = this.getProperty(_) }

  bindingset[propName]
  MethodCallNode getARead(string propName) {
    // TODO: in same view
    exists(WebApp webApp |
      webApp.getAResource() = this.asXmlControl().getFile() and
      webApp.getAResource() = result.getFile()
    ) and
    result.getMethodName() = "get" + capitalize(propName)
  }

  bindingset[propName]
  MethodCallNode getAWrite(string propName) {
    // TODO: in same view
    exists(WebApp webApp |
      webApp.getAResource() = this.asXmlControl().getFile() and
      webApp.getAResource() = result.getFile()
    ) and
    result.getMethodName() = "set" + capitalize(propName)
  }

  /** Holds if this control reads from or writes to a model. */
  predicate accessesModel(UI5Model model) { accessesModel(model, _) }

  /** Holds if this control reads from or writes to a model with regards to a binding path. */
  predicate accessesModel(UI5Model model, XmlBindingPath bindingPath) {
    // Verify that the controller's model has the referenced property
    exists(XmlView view |
      // Both this control and the model belong to the same view
      this = view.getXmlControl() and
      model = view.getController().getModel() and
      model.(UI5InternalModel).getPathString() = bindingPath.getPath() and
      bindingPath.getBindingTarget() = this.asXmlControl().getAnAttribute()
    )
    // TODO: Add case where modelName is present
  }

  /** Get the view that this control is part of. */
  UI5View getView() { result = this.asXmlControl().getFile() }

  /** Get the controller that manages this control. */
  CustomController getController() { result = this.getView().getController() }
}

newtype TUI5ControlProperty = TXmlControlProperty(XmlAttribute property)

class UI5ControlProperty extends TUI5ControlProperty {
  XmlAttribute asXmlControlProperty() { this = TXmlControlProperty(result) }

  string toString() { result = this.asXmlControlProperty().toString() }

  UI5Control getControl() { result.asXmlControl() = this.asXmlControlProperty().getElement() }

  string getName() { result = this.asXmlControlProperty().getName() }

  string getValue() { result = this.asXmlControlProperty().getValue() }
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
      result.getLiteralRepr() = control.getProperty(result.getPropertyName()).getValue()
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
