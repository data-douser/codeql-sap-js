import javascript
import DataFlow
import UI5AMDModule
import semmle.javascript.frameworks.data.internal.ApiGraphModelsExtensions as ApiGraphModelsExtensions

/**
 * Returns all the types that are supertype of base
 * ```
 * - addsTo:
 *     pack: codeql/javascript-all
 *     extensible: typeModel
 *   data:["sap/m/InputBase", "sap/m/Input", ""]
 * ```
 */
bindingset[base]
string getASuperType(string base) {
  result = base or ApiGraphModelsExtensions::typeModel(result, base, "")
}

class JsonView extends JsonObject {
  JsonView() { this.getPropStringValue("Type") = "sap.ui.core.mvc.JSONView" }

  string getControllerName() { result = this.getPropStringValue("controllerName") }

  JsonValue getASourceLocation() {
    exists(JsonObject content, string type, string path, string property |
      content.getParent*() = this and
      content.getPropStringValue("Type").replaceAll(".", "/") = type and
      ApiGraphModelsExtensions::sourceModel(getASuperType(type), path, "remote") and
      property = path.regexpCapture("Instance\\.Member\\[([^\\]]+)\\]", 1) and
      result = content.getPropValue(property)
    )
  }

  JsonValue getAnHTMLiSinkLocation() {
    exists(JsonObject content, string type, string path, string property |
      content.getParent*() = this and
      content.getPropStringValue("Type").replaceAll(".", "/") = type and
      ApiGraphModelsExtensions::sinkModel(getASuperType(type), path, "html-injection") and
      property = path.regexpCapture("Instance\\.Member\\[([^\\]]+)\\]", 1) and
      result = content.getPropValue(property)
    )
  }
}
