private import javascript
private import DataFlow
private import semmle.javascript.security.dataflow.DomBasedXssCustomizations

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

  /**
   * https://sapui5.hana.ondemand.com/sdk/#/api/sap.ui%23methods/sap.ui.define
   */
  class Define extends CallNode, SapElement {
    Define() { this = globalVarRef("sap").getAPropertyRead("ui").getAMethodCall("define") }

    string getDependencyType(int i) {
      result =
        this.getArgument(0).getALocalSource().(ArrayLiteralNode).getElement(i).getStringValue()
    }

    ParameterNode getParameter(int i) {
      result = this.getArgument(1).getALocalSource().(FunctionNode).getParameter(i)
    }

    Project getProject() { result = this.getFile().getParentContainer*() }

    string getModuleFileRelativePath() {
      result = this.getFile().getRelativePath().suffix(getProject().getRelativePath().length() + 1)
    }
  }

  /**
   * `DefinedModule`: A module defined in the current project.
   * `ExternallyDefinedModule`: A module imported into the current project, either from npm or from the test directory.
   */
  newtype TModule =
    DefinedModule(Define d) or
    ExternallyDefinedModule(string s) {
      exists(Define d | s = d.getDependencyType(_) and not s.prefix(1) = ".")
    }

  class SapModule extends TModule {
    string getModuleFileRelativePath() {
      this = DefinedModule(any(Define d | result = d.getModuleFileRelativePath())) or
      this = ExternallyDefinedModule(result)
    }

    string toString() { result = getModuleFileRelativePath() }
  }

  private SourceNode sapControl(TypeTracker t) {
    t.start() and
    exists(Define d, int i |
      /* It has a "sap/ui/core/Control" specifier */
      d.getDependencyType(i) = "sap/ui/core/Control" and
      /* Get the positional parameter at the same index as the specifier */
      result = d.getParameter(i)
    )
    or
    exists(TypeTracker t2 | result = sapControl(t2).track(t2, t))
  }

  SourceNode sapControl() { result = sapControl(TypeTracker::end()) }

  private SourceNode sapController(TypeTracker t) {
    t.start() and
    exists(Define d, int i |
      /* It has a "sap/ui/core/Controller" specifier */
      d.getDependencyType(i) = "sap/ui/core/mvc/Controller" and
      /* Get the positional parameter at the same index as the specifier */
      result = d.getParameter(i)
    )
    or
    exists(TypeTracker t2 | result = sapController(t2).track(t2, t))
  }

  SourceNode sapController() { result = sapController(TypeTracker::end()) }

  class CustomControl extends Extension {
    CustomControl() { getReceiver().getALocalSource() = sapControl() }

    SourceNode getRenderer() {
      result = this.getArgument(1).(ObjectLiteralNode).getAPropertySource("renderer")
    }

    // TODO
    predicate indirectlyExtendedControl(Define define) {
      /*
       * Sketch:
       *     1. Define a predicate that maps the current module to the extended module
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
     * Gets a view object that can be accessed from one of the methods of this controller.
     */
    View getAView() {
      result.getCalleeName() = "getView" and
      exists(ThisNode controllerThis |
        result.(MethodCallNode).getReceiver() = controllerThis.getALocalUse() and
        controllerThis.getBinder() = this.getAMethod()
      )
    }

    SapElement getAnElement() {
      exists(View view |
        view = this.getAView() and
        /* There is a view */
        view.flowsTo(result.(MethodCallNode).getReceiver()) and
        /* The result is a member of this view */
        result.(MethodCallNode).getMethodName() = "byId"
      )
    }

    ThisNode getAThisNode() { result.getBinder() = this.getAMethod() }

    Model getModel() {
      exists(MethodCallNode setModelCall |
        this.getAView().flowsTo(setModelCall.getReceiver()) and
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
      exists(ModuleObject jsonModel |
        jsonModel.flowsTo(this.getCalleeNode()) and
        jsonModel.getDependencyType() = "sap/ui/model/json/JSONModel"
      )
    }

    ObjectLiteralNode getContent() { result.flowsTo(this.getAnArgument()) }

    override string getPathString() { result = constructPathString(this.getContent()) }
  }

  class XmlModel extends Model {
    XmlModel() {
      this instanceof NewNode and
      exists(ModuleObject xmlModel |
        xmlModel.flowsTo(this.getCalleeNode()) and
        xmlModel.getDependencyType() = "sap/ui/model/xml/XMLModel"
      )
    }

    override string getPathString() { result = "WIP" }
  }

  class RenderManager extends SourceNode {
    RenderManager() {
      /*
       * 1. Old RenderManager API:
       * renderer: function (oRm, oControl) { ... }
       */

      this = any(CustomControl c).getRenderer().(FunctionNode).getParameter(0)
      or
      /*
       * 2. New Semantic Rendering API:
       *  renderer: { apiVersion: 2, render: function(oRm, oControl) { ... } }
       */

      this =
        any(CustomControl c)
            .getRenderer()
            .getAPropertySource("render")
            .(FunctionNode)
            .getParameter(0)
      or
      exists(int i |
        // The control's renderer object
        this = any(CustomControl c).getRenderer().getALocalSource() and
        // ... is an imported one, thus found in a parameter of a Define
        this = any(Define d).getParameter(i)
      )
      or
      /*
       * 3. Through `new` keyword on an imported constructor
       */

      exists(NewNode instantiation, ModuleObject module_ |
        this = instantiation.getAConstructorInvocation(module_.getName())
      )
    }

    CallNode getAnUnsafeHtmlCall() {
      exists(string calleeName |
        result = this.(DataFlow::SourceNode).getAMemberCall(calleeName) and
        calleeName = ["write", "unsafeHtml"]
      )
    }
  }

  class ModuleObject extends ParameterNode {
    ModuleObject() { this = any(Define d).getParameter(_) }

    Define getDefine() { result.getArgument(1).(FunctionNode).getParameter(_) = this }

    string getDependencyType() {
      exists(int i |
        this.getDefine().getParameter(i) = this and result = this.getDefine().getDependencyType(i)
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
      any(ModuleObject module_).flowsTo(this.getReceiver()) and
      /* 2. The method name is `extend` */
      this.(MethodCallNode).getMethodName() = "extend"
    }

    string getName() { result = this.getArgument(0).asExpr().(StringLiteral).getValue() }

    ObjectLiteralNode getContent() { result = this.getArgument(1) }

    Metadata getMetadata() { result = this.getContent().getAPropertySource("metadata") }

    /** Gets the `sap.ui.define` call that wraps this extension. */
    Define getDefine() { this.getEnclosingFunction() = result.getArgument(1).asExpr() }
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

  abstract class View extends SapElement {
    SapElement getAnElement() {
      exists(CustomController controller |
        result.(MethodCallNode).getMethodName() = "byId" and
        this.flowsTo(result.(MethodCallNode).getReceiver()) and
        this = controller.getAView()
      )
    }
  }

  /*
   * 1. XMLView
   *    var oView = XMLView(...)
   */

  class XmlView extends View {
    XmlView() {
      this instanceof NewNode and
      exists(ModuleObject xmlView |
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
    exists(Define d, int i |
      /* It has a "sap/ui/core/Controller" specifier */
      d.getDependencyType(i) = "sap/ui/core/mvc/View" and
      /* Get the positional parameter at the same index as the specifier */
      result = d.getParameter(i)
    )
    or
    exists(TypeTracker t2 | result = sapView(t2).track(t2, t))
  }

  SourceNode sapView() { result = sapView(TypeTracker::end()) }

  class CustomView extends View, Extension {
    CustomView() { this.getReceiver().getALocalSource() = sapView() }
  }

  ValueNode valueFromElement() {
    exists(CustomController controller, SapElement element, MethodCallNode getCall |
      element = controller.getAView().getAnElement() and
      getCall = element.getAMethodCall() and
      getCall.getMethodName() = "getValue" and
      result = getCall
    )
  }

  class UnsafeHtmlXssSource extends DomBasedXss::Source {
    UnsafeHtmlXssSource() { this = valueFromElement() }
  }

  class UnsafeHtmlXssSink extends DomBasedXss::Sink {
    UnsafeHtmlXssSink() { this = any(RenderManager rm).getAnUnsafeHtmlCall().getArgument(0) }
  }
}
