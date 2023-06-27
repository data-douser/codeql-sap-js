private import javascript
private import DataFlow
import UI5::UI5

predicate builtInControl(string qualifiedTypeUri) {
  qualifiedTypeUri =
    [
      "sap.m", // https://sapui5.hana.ondemand.com/#/api/sap.m: The main UI5 control library, with responsive controls that can be used in touch devices as well as desktop browsers.
      "sap.f", // https://sapui5.hana.ondemand.com/#/api/sap.f: SAPUI5 library with controls specialized for SAP Fiori apps.
      "sap.ui" // https://sapui5.hana.ondemand.com/#/api/sap.ui: The sap.ui namespace is the central OpenAjax compliant entry point for UI related JavaScript functionality provided by SAP.
    ]
}

class UI5XmlView extends XmlElement {
  UI5XmlView() { this.getNamespace().getUri() = "sap.ui.core.mvc" and this.getName() = "View" }

  Controller getController() {
    // The controller name should match
    result.getName() = this.getAttributeValue("controllerName") and
    // The View XML file and the controller are in a same project
    exists(Project project |
      project.isInThisProject(this.getFile()) and project.isInThisProject(result.getFile())
    )
  }

  XmlElement getXmlControlTag() {
    result =
      any(XmlElement element |
        // Either a builtin control provided by UI5
        element = this.getAChild+() and builtInControl(element.getNamespace().getUri())
        or
        // or a custom control with implementation code found in the project
        exists(Control control, Project project |
          element = this.getAChild+() and
          control.getName() = element.getNamespace().getUri() + "." + element.getName() and
          project.isInThisProject(control.getFile()) and
          project.isInThisProject(element.getFile())
        )
      )
  }

  /**
   * Gets the qualified type, such as `sap.m.Page`.
   */
  string getQualifiedType() { result = this.getNamespace().getUri() + "." + this.getName() }

  /**
   * Get the implementation code in Javascript that accompanies this Xml Control tag. Only works for custom controls.
   *
   * For example, get Book.js for <Book attr="val1", .../>.
   */
  Extension getJSDefinition() {
    result = any(Extension extension | extension.getName() = this.getQualifiedType())
  }

  // Controller getController
  MethodCallNode getAReference() {
    result.getEnclosingFunction() = any(Controller controller).getAMethod().asExpr() and
    result.getMethodName() = "byId" and
    result.getArgument(0).asExpr().(StringLiteral).getValue() = this.getAttributeValue("id")
  }
}

from XmlFile xmlFile
where
  xmlFile.getAbsolutePath() =
    "/Users/jslee/Work/WorkRepos/codeql-sap-js/integration-tests/xss-example/webapp/view/App.view.xml"
select xmlFile, xmlFile.getARootElement(), xmlFile.getARootElement().getNamespace().getUri()
