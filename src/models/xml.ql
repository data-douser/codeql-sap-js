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

  CustomController getController() {
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
        element = this.getAChild+() and
        // Either a builtin control provided by UI5
        (
          builtInControl(element.getNamespace().getUri())
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

class UI5XmlControl extends UI5XmlElement {
  UI5XmlControl() { this.getParent+() = any(UI5XmlView view) }

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

  /**
   * Holds if the control accesses some property of the model.
   * Look for the data binding: {/some/nested/property} or {modelName>/some/nested/property} where
   * controller.setModel(oModel, "modelName") for some controller.
   */
  predicate accessesModel() {
    // 1. verify that the controller's model has the referenced property
    this.getAnAttribute().(DataBinding).getPathString() =
      any(Model model |
        exists(UI5XmlView view |
          view.getXmlControl() = this and model = view.getController().getAModel()
        )
      ).getPathString() and
    any()
    // 2. And this control is referring to the property through databinding
  }
}

/** Data binding found in an XMLView: e.g. `{/some/nested/property}` or `{modelName>/some/nested/property}`. */
class DataBinding extends XmlAttribute {
  DataBinding() {
    // Syntactic property 1: this is an XML attribute of a control
    exists(UI5XmlControl control | control.getAttribute(_) = this) and
    // Syntactic property 2: this is wrapped inside curly braces
    this.getValue().charAt(0) = "{" and
    this.getValue().charAt(this.getValue().length() - 1) = "}"
  }

  Model getModel() {
    exists(UI5XmlView view |
      view.getXmlControl().getAnAttribute() = this and
      view.getController().getAModel() = result
    )
  }

  string getPathString() { result = this.getValue().substring(1, this.getValue().length() - 1) }
}

from XmlFile xmlFile
where
  xmlFile.getAbsolutePath() =
    "/Users/jslee/Work/WorkRepos/codeql-sap-js/integration-tests/xss-example/webapp/view/App.view.xml"
select xmlFile, xmlFile.getARootElement(), xmlFile.getARootElement().getNamespace().getUri()
