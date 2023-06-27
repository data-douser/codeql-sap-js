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

abstract class UI5XmlElement extends XmlElement {
  string getQualifiedType() { result = this.getNamespace().getUri() + "." + this.getName() }
}

class UI5XmlView extends UI5XmlElement {
  UI5XmlView() {
    this.getNamespace().getUri() = "sap.ui.core.mvc" and
    this.getName() = "View" and
    this = any(XmlFile xmlFile).getARootElement()
  }

  Controller getController() {
    // The controller name should match
    result.getName() = this.getAttributeValue("controllerName") and
    // The View XML file and the controller are in a same project
    exists(Project project |
      project.isInThisProject(this.getFile()) and project.isInThisProject(result.getFile())
    )
  }

  UI5XmlControl getXmlControl() {
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
}

class UI5XmlControl extends UI5XmlElement {
  UI5XmlControl() { this.getParent+() = any(UI5XmlView view) }

  Extension getJSDefinition() {
    result = any(Extension extension | extension.getName() = this.getQualifiedType())
  }

  MethodCallNode getAReference() {
    result.getEnclosingFunction() = any(Controller controller).getAMethod().asExpr() and
    result.getMethodName() = "byId" and
    result.getArgument(0).asExpr().(StringLiteral).getValue() = this.getAttributeValue("id")
  }

  /**
   * Holds if the control accesses some property of the model.
   * Look for the data binding: {/some/nested/property} or {modelName>/some/nested/property} where
   * controller.setModel(oModel, "modelName") for some controller.
   */
  predicate accessesModel() { this.getAnAttribute() instanceof DataBinding }
}

/** Data binding found in an XMLView: e.g. {/some/nested/property} or {modelName>/some/nested/property} */
class DataBinding extends XmlAttribute {
  DataBinding() {
    // Syntactic property 1: this is an XML attribute of a control
    exists(UI5XmlControl control | control.getAttribute(_) = this) and
    // Syntactic property 2: this is wrapped inside curly braces
    this.getValue().charAt(0) = "{" and
    this.getValue().charAt(this.getValue().length() - 1) = "}"
  }

  Model getModel() {
    // WIP
    exists(UI5XmlView view | view.getController().getAModel() = result)
  }
}

from XmlFile xmlFile
where
  xmlFile.getAbsolutePath() =
    "/Users/jslee/Work/WorkRepos/codeql-sap-js/integration-tests/xss-example/webapp/view/App.view.xml"
select xmlFile, xmlFile.getARootElement(), xmlFile.getARootElement().getNamespace().getUri()
