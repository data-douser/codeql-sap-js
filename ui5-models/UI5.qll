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
  class Define extends CallNode {
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

  class UnsafeHtmlXssSink extends DomBasedXss::Sink {
    UnsafeHtmlXssSink() { this = any(RenderManager rm).getAnUnsafeHtmlCall().getArgument(0) }
  }
}
