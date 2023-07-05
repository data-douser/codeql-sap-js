private import javascript
private import DataFlow
private import semmle.javascript.security.dataflow.DomBasedXssCustomizations
private import XmlView

module UI5 {
  class Project extends Folder {
    /**
     * An UI5 project root folder.
     */
    Project() { exists(File yamlFile | yamlFile = this.getFile("ui5.yaml")) }

    /**
     * The `ui5.yaml` file that declares a UI5 application.
     */
    File getProjectYaml() { result = this.getFile("ui5.yaml") }

    predicate isInThisProject(File file) { this = file.getParentContainer*() }
  }

  /**
   * https://sapui5.hana.ondemand.com/sdk/#/api/sap.ui.loader%23methods/sap.ui.loader.config
   */
  class Loader extends CallNode {
    Loader() { this = globalVarRef("sap").getAPropertyRead("ui").getAMethodCall("loader") }
  }

  abstract class UserModule extends SapElement {
    abstract string getADependencyType();

    abstract string getModuleFileRelativePath();

    abstract RequiredObject getRequiredObject(string dependencyType);
  }

  /**
   * https://sapui5.hana.ondemand.com/sdk/#/api/sap.ui%23methods/sap.ui.define
   */
  class SapDefineModule extends CallNode, UserModule {
    SapDefineModule() { this = globalVarRef("sap").getAPropertyRead("ui").getAMethodCall("define") }

    override string getADependencyType() { result = this.getDependencyType(_) }

    override string getModuleFileRelativePath() { result = this.getFile().getRelativePath() }

    string getDependencyType(int i) {
      result =
        this.getArgument(0).getALocalSource().(ArrayLiteralNode).getElement(i).getStringValue()
    }

    override RequiredObject getRequiredObject(string dependencyType) {
      exists(int i |
        this.getDependencyType(i) = dependencyType and
        result = this.getArgument(1).getALocalSource().(FunctionNode).getParameter(i)
      )
    }

    Project getProject() { result = this.getFile().getParentContainer*() }
  }

  class JQuerySap extends DataFlow::SourceNode {
    JQuerySap() {
      exists(DataFlow::GlobalVarRefNode global |
        global.getName() = "jQuery" and
        this = global.getAPropertyRead("sap")
      )
    }
  }

  class JQueryDefineModule extends UserModule, DataFlow::MethodCallNode {
    JQueryDefineModule() { exists(JQuerySap jquerySap | jquerySap.flowsTo(this.getReceiver())) }

    override string getADependencyType() {
      result = this.getArgument(0).asExpr().(StringLiteral).getValue()
    }

    override string getModuleFileRelativePath() { result = this.getFile().getRelativePath() }

    /** WARNING: toString() Hack! */
    override RequiredObject getRequiredObject(string dependencyType) {
      result.toString() = dependencyType and
      this.getADependencyType() = dependencyType
    }
  }

  private RequiredObject sapControl(TypeTracker t) {
    t.start() and
    exists(UserModule d, string dependencyType |
      dependencyType = ["sap/ui/core/Control", "sap.ui.core.Control"]
    |
      /* It has a "sap/ui/core/Control" specifier */
      d.getADependencyType() = dependencyType and
      /* Get the positional parameter at the same index as the specifier */
      result = d.getRequiredObject(dependencyType)
    )
    or
    exists(TypeTracker t2 | result = sapControl(t2).track(t2, t))
  }

  SourceNode sapControl() { result = sapControl(TypeTracker::end()) }

  private SourceNode sapController(TypeTracker t) {
    t.start() and
    exists(UserModule d, string dependencyType |
      dependencyType = ["sap/ui/core/mvc/Controller", "sap.ui.core.mvc.Controller"]
    |
      /* It has a "sap/ui/core/Controller" specifier */
      d.getADependencyType() = dependencyType and
      /* Get the positional parameter at the same index as the specifier */
      result = d.getRequiredObject(dependencyType)
    )
    or
    exists(TypeTracker t2 | result = sapController(t2).track(t2, t))
  }

  SourceNode sapController() { result = sapController(TypeTracker::end()) }

  class CustomControl extends Extension {
    CustomControl() { this.getReceiver().getALocalSource() = sapControl() }

    FunctionNode getRenderer() {
      exists(SourceNode propValue |
        propValue = this.getArgument(1).(ObjectLiteralNode).getAPropertySource("renderer") and
        (
          /*
           * 1. Old RenderManager API:
           * renderer: function (oRm, oControl) { ... }
           */

          propValue instanceof FunctionNode and result = propValue
          or
          /*
           * 2. New Semantic Rendering API:
           *  renderer: { apiVersion: 2, render: function(oRm, oControl) { ... } }
           */

          propValue instanceof ObjectLiteralNode and
          result = propValue.getAPropertySource("render").(FunctionNode)
          or
          /*
           * 3. The control's renderer object is an imported one
           */

          exists(string dependencyType |
            result = propValue.getALocalSource() and
            result = any(UserModule d).getRequiredObject(dependencyType)
          )
          or
          /*
           * 4. The control's renderer is referred to as a string ID
           */

          propValue.asExpr() instanceof StringLiteral and
          result =
            any(Extension extend | extend.getName() = propValue.asExpr().(StringLiteral).getValue())
                .getArgument(1)
                .(ObjectLiteralNode)
                .getAPropertySource("render")
        )
      )
      or
      /*
       * 5. There is an implicit binding between the control and its renderer with the naming convention: e.g. foo.js and fooRenderer.js
       */

      this.getFile().getExtension() = "js" and
      result =
        any(Extension extend |
          extend.getFile().getExtension() = "js" and
          result.getFile().getBaseName().splitAt(".", 0) =
            this.getFile().getBaseName().splitAt(".", 0) + "Renderer"
        ).getArgument(1).(ObjectLiteralNode).getAPropertySource("render")
    }

    // TODO
    predicate indirectlyExtendedControl(SapDefineModule define) {
      /*
       * Sketch:
       *     1. SapDefineModule a predicate that maps the current module to the extended module
       *     2. * or + the predicate
       */

      any()
    }
  }

  class CustomController extends Extension {
    CustomController() {
      this instanceof MethodCallNode and this.getReceiver().getALocalSource() = sapController()
    }

    FunctionNode getAMethod() {
      result = this.getArgument(1).(ObjectLiteralNode).getAPropertySource().(FunctionNode)
    }

    /**
     * Gets a reference to a view object that can be accessed from one of the methods of this controller.
     */
    MethodCallNode getAViewReference() {
      result.getCalleeName() = "getView" and
      exists(ThisNode controllerThis |
        result.(MethodCallNode).getReceiver() = controllerThis.getALocalUse() and
        controllerThis.getBinder() = this.getAMethod()
      )
    }

    /**
     * Gets the declaration of the view object that is associated with this controller.
     */
    View getView() {
      /* 1. The controller uses a predefined view: (HTMLView|XMLView|JSONView|JSView|TemplateView) */
      none() // WIP
      or
      /* 2. The controller uses a custom view */
      none() // WIP: is custom view used in practice && do we want to model it?
    }

    MethodCallNode getAnElementReference() {
      exists(MethodCallNode viewRef |
        viewRef = this.getAViewReference() and
        /* There is a view */
        viewRef.flowsTo(result.(MethodCallNode).getReceiver()) and
        /* The result is a member of this view */
        result.(MethodCallNode).getMethodName() = "byId"
      )
    }

    ThisNode getAThisNode() { result.getBinder() = this.getAMethod() }

    Model getModel() {
      exists(MethodCallNode setModelCall |
        this.getAViewReference().flowsTo(setModelCall.getReceiver()) and
        setModelCall.getMethodName() = "setModel" and
        result.flowsTo(setModelCall.getAnArgument())
      )
    }
  }

  abstract class Model extends SapElement {
    abstract string getPathString();
  }

  private string constructPathStringInner(Expr object) {
    if not object instanceof ObjectExpr
    then result = ""
    else
      exists(Property property | property = object.(ObjectExpr).getAProperty().(ValueProperty) |
        result = constructPathStringInner(property.getInit()) + "/" + property.getName()
      )
  }

  string constructPathString(DataFlow::ObjectLiteralNode object) {
    result = constructPathStringInner(object.asExpr())
  }

  class JsonModel extends Model {
    JsonModel() {
      this instanceof NewNode and
      exists(RequiredObject jsonModel |
        jsonModel.flowsTo(this.getCalleeNode()) and
        jsonModel.getDependencyType() = "sap/ui/model/json/JSONModel"
      )
    }

    ObjectLiteralNode getContent() { result.flowsTo(this.getAnArgument()) }

    override string getPathString() { result = constructPathString(this.getContent()) }

    /**
     * A model possibly supporting two-way binding explicitly set as a one-way binding model.
     */
    predicate isOneWayBinding() {
      exists(MethodCallNode call, BindingMode bindingMode |
        this.flowsTo(call.getReceiver()) and
        call.getMethodName() = "setDefaultBindingMode" and
        bindingMode.getOneWay().flowsTo(call.getArgument(0))
      )
    }
  }

  class XmlModel extends Model {
    XmlModel() {
      this instanceof NewNode and
      exists(RequiredObject xmlModel |
        xmlModel.flowsTo(this.getCalleeNode()) and
        xmlModel.getDependencyType() = "sap/ui/model/xml/XMLModel"
      )
    }

    override string getPathString() { result = "WIP" }
  }

  class BindingMode extends RequiredObject {
    BindingMode() { this.getDependencyType() = "sap/ui/model/BindingMode" }

    PropRead getOneWay() { result = this.getAPropertyRead("OneWay") }

    PropRead getTwoWay() { result = this.getAPropertyRead("TwoWay") }

    PropRead getDefault() { result = this.getAPropertyRead("Default") }

    PropRead getOneTime() { result = this.getAPropertyRead("OneTime") }
  }

  class RenderManager extends SourceNode {
    RenderManager() {
      this = any(CustomControl c).getRenderer().getParameter(0)
      or
      /*
       * Through `new` keyword on an imported constructor
       */

      exists(NewNode instantiation |
        this = instantiation.getAConstructorInvocation("RenderManager")
      )
    }

    CallNode getAnUnsafeHtmlCall() {
      exists(string calleeName |
        result = this.(DataFlow::SourceNode).getAMemberCall(calleeName) and
        calleeName = ["write", "unsafeHtml"]
      )
    }
  }

  class RequiredObject extends SourceNode {
    RequiredObject() {
      exists(string dependencyType, int i |
        any(SapDefineModule sapModule).getDependencyType(i) = dependencyType and
        this =
          any(SapDefineModule sapModule)
              .getArgument(1)
              .getALocalSource()
              .(FunctionNode)
              .getParameter(i)
      )
      or
      exists(string dependencyType |
        this.toString() = dependencyType and
        any(JQueryDefineModule jQueryModule).getADependencyType() = dependencyType
      )
    }

    UserModule getDefiningModule() { result.getArgument(1).(FunctionNode).getParameter(_) = this }

    string getDependencyType() {
      exists(string dependencyType |
        this.getDefiningModule().getRequiredObject(dependencyType) = this and
        result = this.getDefiningModule().getADependencyType()
      )
    }
  }

  /**
   * Controller.extend or
   * Control.extend
   */
  class Extension extends SapElement, MethodCallNode {
    Extension() {
      /* 1. The receiver object is an imported one */
      any(RequiredObject module_).flowsTo(this.getReceiver()) and
      /* 2. The method name is `extend` */
      this.(MethodCallNode).getMethodName() = "extend"
    }

    string getName() { result = this.getArgument(0).asExpr().(StringLiteral).getValue() }

    ObjectLiteralNode getContent() { result = this.getArgument(1) }

    Metadata getMetadata() { result = this.getContent().getAPropertySource("metadata") }

    /** Gets the `sap.ui.define` call that wraps this extension. */
    SapDefineModule getDefine() { this.getEnclosingFunction() = result.getArgument(1).asExpr() }
  }

  /**
   * The property metadata found in an Extension.
   */
  class Metadata extends ObjectLiteralNode {
    Metadata() { this = any(Extension e).getContent().getAPropertySource("metadata") }

    Node getAProperty(string name) {
      result = this.getAPropertySource("properties").getAPropertyReference(name)
    }

    Extension getExtension() { result = any(Extension extend | extend.getMetadata() = this) }

    MethodCallNode getAWrite() {
      exists(string propName |
        result.getMethodName() = "setProperty" and
        result.getArgument(0).asExpr().(StringLiteral).getValue() = propName and
        exists(this.getAProperty(propName))
      )
    }

    MethodCallNode getAWrite(string propName) {
      result.getMethodName() = "setProperty" and
      result.getArgument(0).asExpr().(StringLiteral).getValue() = propName and
      exists(this.getAProperty(propName))
    }

    MethodCallNode getARead() {
      exists(string propName |
        result.getMethodName() = "get" + propName.prefix(1).toUpperCase() + propName.suffix(1) and
        exists(this.getAProperty(propName))
      )
    }

    MethodCallNode getARead(string propName) {
      result.getMethodName() = "get" + propName.prefix(1).toUpperCase() + propName.suffix(1) and
      exists(this.getAProperty(propName))
    }
  }

  /**
   * Result of View.byId().
   * https://sapui5.hana.ondemand.com/sdk/#/api/sap.ui.core.Element
   * https://sapui5.hana.ondemand.com/sdk/#/api/sap.ui.core.mvc.Controller%23methods/byId
   */
  abstract class SapElement extends InvokeNode { }

  abstract class View extends SapElement { }

  /*
   * 1. XMLView
   *    var oView = XMLView(...)
   */

  class XmlView extends View {
    XmlView() {
      this instanceof NewNode and
      exists(RequiredObject xmlView |
        xmlView.flowsTo(this.getCalleeNode()) and
        xmlView.getDependencyType() = "sap/ui/core/mvc/XMLView"
      )
    }
  }

  /*
   * 2. Extension of a view
   *      View.extend("some.view", { ... })
   */

  private SourceNode sapView(TypeTracker t) {
    t.start() and
    exists(SapDefineModule d, string dependencyType |
      dependencyType = ["sap/ui/core/Control", "sap.ui.core.Control"]
    |
      /* It has a "sap/ui/core/Controller" specifier */
      d.getDependencyType(_) = dependencyType and
      /* Get the positional parameter at the same index as the specifier */
      result = d.getRequiredObject(dependencyType)
    )
    or
    exists(TypeTracker t2 | result = sapView(t2).track(t2, t))
  }

  SourceNode sapView() { result = sapView(TypeTracker::end()) }

  class CustomView extends View, Extension {
    CustomView() { this.getReceiver().getALocalSource() = sapView() }
  }

  MethodCallNode valueFromElement() {
    exists(CustomController controller |
      result = controller.getAnElementReference().getAMethodCall() and
      result.getMethodName().substring(0, 3) = "get"
    )
  }

  class UnsafeHtmlXssSource extends DomBasedXss::Source {
    UnsafeHtmlXssSource() {
      this = valueFromElement()
      or
      exists(UI5XmlView xmlView, UI5XmlControl control |
        control = xmlView.getXmlControl() and
        control.writesToModel() and
        this = xmlView.getController().getModel()
      )
    }
  }

  class UnsafeHtmlXssSink extends DomBasedXss::Sink {
    UnsafeHtmlXssSink() { this = any(RenderManager rm).getAnUnsafeHtmlCall().getArgument(0) }
  }
}
