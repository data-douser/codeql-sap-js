import javascript
import DataFlow
import semmle.javascript.security.dataflow.DomBasedXssCustomizations

module UI5 {
  class Project extends Folder {
    /**
     * The `ui5.yaml` file that declares a UI5 application.
     */
    Project() { exists(File yamlFile | yamlFile = this.getFile("ui5.yaml")) }

    File getProjectYaml() { result = this.getFile("ui5.yaml") }
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

  class Module extends TModule {
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

  class Control extends CallNode {
    Control() { getReceiver().getALocalSource() = sapControl() and getCalleeName() = "extend" }

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

  class Controller extends CallNode {
    Controller() {
      getReceiver().getALocalSource() = sapController() and getCalleeName() = "extend"
    }

    FunctionNode getAMethod() {
      result = this.getArgument(1).(ObjectLiteralNode).getAPropertySource().(FunctionNode)
    }

    /**
     * Gets a view object that can be accessed from one of the methods of this controller.
     */
    View getAView() {
      result.getCalleeName() = "getView" and
      exists(ThisNode this_ |
        result.getReceiver() = this_.getALocalUse() and
        exists(FunctionNode method | method = getAMethod() and this_.getBinder() = method)
      )
    }

    SapElement getAnElement() {
      /* There is a view */
      exists(View view | view.flowsTo(result))
      /* There is a member of this view */
    }
  }

  class RenderManager extends SourceNode {
    RenderManager() {
      this = any(Control c).getRenderer().(FunctionNode).getParameter(0)
      or
      exists(int i |
        // The control's renderer object
        this = any(Control c).getRenderer().getALocalSource() and
        // ... is an imported one, thus found in a parameter of a Define
        this = any(Define d).getParameter(i)
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
  }

  /**
   * Controller.extend or
   * Control.extend
   */
  class Extension extends MethodCallNode {
    Extension() {
      /* 1. The receiver object is an imported one */
      any(ModuleObject module_).flowsTo(this.getReceiver()) and
      /* 2. The method name is `extend` */
      this.getMethodName() = "extend"
    }

    ObjectLiteralNode getContent() { result = this.getArgument(1) }

    Metadata getMetadata() { result = this.getContent().getAPropertySource("metadata") }
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
        exists(getAProperty(propName))
      )
    }
  }

  /**
   * Result of View.byId().
   * https://sapui5.hana.ondemand.com/sdk/#/api/sap.ui.core.Element
   * https://sapui5.hana.ondemand.com/sdk/#/api/sap.ui.core.mvc.Controller%23methods/byId
   */
  abstract class SapElement extends CallNode { }

  class View extends SapElement {
    View() {
      /* 1. A return value of `this.getView` where `this` is a Controller */
      // exists(Controller controller | this = controller.getAView())
      any()
      or
      /*
       * 2. Extension of a view
       *      View.extend("some.view", { ... })
       */

      none() // TODO, not needed right now
      or
      /*
       * 3. XMLView
       *    var oView = XMLView(...)
       */

      none() // TODO, not needed right now
      or
      /*
       * 4. sap.ui.xmlview({
       *                    viewContent : jQuery("#myXmlView").html()
       *                }).placeAt("contentXMLView");
       */

      none() // TODO, not needed right now
    }

    SapElement getAnElement() {
      exists(Controller controller, View view |
        result.(MethodCallNode).getMethodName() = "byId" and
        view.flowsTo(result.getReceiver()) and
        view = controller.getAView() and
        result = result
      )
    }
  }

  ValueNode valueFromElement() {
    exists(Controller controller, SapElement element, MethodCallNode getCall |
      element = controller.getAView().getAnElement() and
      getCall = element.getAMethodCall() and
      getCall.getMethodName().prefix(3) = "get" and
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
