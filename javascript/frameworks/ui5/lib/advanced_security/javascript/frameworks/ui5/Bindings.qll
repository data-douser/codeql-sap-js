import javascript
import advanced_security.javascript.frameworks.ui5.BindingStringParser as MakeBindingStringParser

private class ContextBindingAttribute extends XmlAttribute {
  ContextBindingAttribute() { this.getName() = "binding" }
}

// TODO: add support for binding strings in strings such as `description: "Some {/description}"`
private newtype TBindingString =
  TBindingStringFromLiteral(StringLiteral stringLiteral) {
    stringLiteral.getValue().matches("{%}") 
  }
  or
  TBindingStringFromXmlAttribute(XmlAttribute attribute) {
    attribute.getValue().matches("{%}")
  }
  or
  TBindingStringFromJsonProperty(JsonObject object, string propertyName) {
    object.getPropStringValue(propertyName).matches("{%}")
  }
  or
  TBindingStringFromBindElementMethodCall(BindElementMethodCallNode bindElement) {
    bindElement.getArgument(0).getALocalSource().asExpr().(StringLiteral).getValue().matches("{%}")
  }
  or
  TBindingStringFromBindPropertyMethodCall(BindPropertyMethodCallNode bindProperty) {
    bindProperty.getArgument(1).getALocalSource().asExpr().(StringLiteral).getValue().matches("{%}")
  }

private class BindingStringReader extends TBindingString {
  string toString() {
    result = this.getBindingString()
  }

  string getBindingString() {
    exists(StringLiteral stringLiteral |
      this = TBindingStringFromLiteral(stringLiteral) and
      result = stringLiteral.getValue()
    )
    or
    exists(XmlAttribute attribute |
      this = TBindingStringFromXmlAttribute(attribute) and
      result = attribute.getValue()
    )
    or
    exists(JsonObject object, string propertyName |
      this = TBindingStringFromJsonProperty(object, propertyName) and
      result = object.getPropStringValue(propertyName)
    )
    or
    exists(BindElementMethodCallNode bindElement |
      this = TBindingStringFromBindElementMethodCall(bindElement) and
      result = bindElement.getArgument(0).getALocalSource().asExpr().(StringLiteral).getValue()
    )
    or
    exists(BindPropertyMethodCallNode bindProperty |
      this = TBindingStringFromBindPropertyMethodCall(bindProperty) and
      result = bindProperty.getArgument(1).getALocalSource().asExpr().(StringLiteral).getValue()
    )

  }

  Location getLocation() {
    exists(StringLiteral stringLiteral |
      this = TBindingStringFromLiteral(stringLiteral) and
      result = stringLiteral.getLocation()
    )
    or
    exists(XmlAttribute attribute |
      this = TBindingStringFromXmlAttribute(attribute) and
      result = attribute.getLocation()
    )
    or
    exists(JsonObject object, string propertyName |
      this = TBindingStringFromJsonProperty(object, propertyName) and
      result = object.getPropValue(propertyName).getLocation()
    )
    or
    exists(BindElementMethodCallNode bindElement |
      this = TBindingStringFromBindElementMethodCall(bindElement) and
      result = bindElement.getArgument(0).getALocalSource().asExpr().(StringLiteral).getLocation()
    )
    or
    exists(BindPropertyMethodCallNode bindProperty |
      this = TBindingStringFromBindPropertyMethodCall(bindProperty) and
      result = bindProperty.getArgument(1).getALocalSource().asExpr().(StringLiteral).getLocation()
    )
  }
}

private module BindingStringParser =
  MakeBindingStringParser::BindingStringParser<BindingStringReader>;

private class StaticBindingValue = BindingStringParser::Binding;

class BindingString extends string {
  bindingset[this]
  BindingString() { this = any(BindingStringReader reader).getBindingString() }
}

private class BindPropertyMethodCallNode extends DataFlow::MethodCallNode {
  BindPropertyMethodCallNode() { this.getMethodName() = "bindProperty" }
}

private class BindElementMethodCallNode extends DataFlow::MethodCallNode {
  BindElementMethodCallNode() { this.getMethodName() = "bindElement" }
}

private class BindValueMethodCallNode extends DataFlow::MethodCallNode {
  BindValueMethodCallNode() { this.getMethodName() = "bindValue" }
}

private newtype TLateJavaScriptPropertyBindingMethodCall =
  TBindProperty(BindPropertyMethodCallNode bindProperty) or
  TBindValue(BindValueMethodCallNode bindValue)

private class LateJavaScriptPropertyBindingMethodCall extends TLateJavaScriptPropertyBindingMethodCall {
  string toString() {
    exists(BindPropertyMethodCallNode bindProperty |
      this = TBindProperty(bindProperty) and
      result =
        "bindProperty(" + bindProperty.getArgument(0).toString() + ", " +
          bindProperty.getArgument(1).toString() + ")"
    )
    or
    exists(BindValueMethodCallNode bindValue |
      this = TBindValue(bindValue) and
      result = "bindValue(" + bindValue.getArgument(0).toString() + ", " + ")"
    )
  }

  DataFlow::MethodCallNode asMethodCallNode() {
    this = TBindProperty(result)
    or
    this = TBindValue(result)
  }

  string getPropertyName() {
    exists(BindPropertyMethodCallNode bindProperty |
      this = TBindProperty(bindProperty) and
      result = bindProperty.getArgument(0).getStringValue()
    )
    or
    exists(BindValueMethodCallNode bindValue |
      this = TBindValue(bindValue) and
      result = "value"
    )
  }

  DataFlow::Node getBinding() {
    exists(BindPropertyMethodCallNode bindProperty |
      this = TBindProperty(bindProperty) and
      result = bindProperty.getArgument(1).getALocalSource()
    )
    or
    exists(BindValueMethodCallNode bindValue |
      this = TBindValue(bindValue) and
      result = bindValue.getArgument(0).getALocalSource()
    )
  }
}

private predicate earlyPathPropertyBinding(
  DataFlow::NewNode newNode, DataFlow::SourceNode binding, DataFlow::Node bindingPath
) {
  // Property binding via an object literal binding with property `path`.
  exists(Property path, DataFlow::Node pathValue |
    newNode.getAnArgument().getALocalSource() = binding and
    binding.asExpr().(ObjectExpr).getPropertyByName("path") = path and
    pathValue = path.getInit().flow()
  |
    if exists(pathValue.getALocalSource())
    then pathValue.getALocalSource() = bindingPath
    else pathValue = bindingPath // e.g., path: "/" + someVar
  )
  or
  // Propery binding where the binding is the binding path.
  exists(Property prop |
    newNode.getAnArgument().getALocalSource().asExpr().(ObjectExpr).getAProperty() = prop and
    prop.getInit().flow().getALocalSource() = binding and
    binding = bindingPath and
    binding.getStringValue() instanceof BindingString
  )
  or
  exists(
    DataFlow::ObjectLiteralNode valueBinding, Property valueProperty, Property partsProperty,
    DataFlow::ArrayLiteralNode partsArray, DataFlow::ObjectLiteralNode partElement,
    DataFlow::Node pathValue
  |
    valueProperty = binding.asExpr().(ObjectExpr).getPropertyByName("value") and
    valueProperty.getInit().flow().getALocalSource() = valueBinding and
    partsProperty = valueBinding.asExpr().(ObjectExpr).getPropertyByName("parts") and
    partsArray = partsProperty.getInit().flow().getALocalSource() and
    partElement = partsArray.getAnElement() and
    pathValue = partElement.asExpr().(ObjectExpr).getPropertyByName("path").getInit().flow() and
    if exists(pathValue.getALocalSource())
    then pathValue.getALocalSource() = bindingPath
    else pathValue = bindingPath
  |
    newNode.getAnArgument().getALocalSource() = binding
  )
}

private predicate latePathBinding(
  DataFlow::MethodCallNode bindingCall, DataFlow::SourceNode binding, DataFlow::Node bindingPath
) {
  (
    exists(LateJavaScriptPropertyBindingMethodCall lateJavaScriptPropertyBindingMethodCall |
      bindingCall = lateJavaScriptPropertyBindingMethodCall.asMethodCallNode() and
      binding = lateJavaScriptPropertyBindingMethodCall.getBinding()
    )
    or
    exists(BindElementMethodCallNode bindElementMethodCall |
      bindingCall = bindElementMethodCall and
      binding = bindElementMethodCall.getArgument(0).getALocalSource()
    )
  ) and
  if exists(binding.getStringValue())
  then bindingPath = binding
  else
    exists(DataFlow::ObjectLiteralNode bindingAsObject | binding = bindingAsObject |
      if exists(bindingAsObject.getAPropertyWrite("path"))
      then bindingPath = bindingAsObject.getAPropertyWrite("path").getRhs()
      else
        // Assume composite binding with parts property
        exists(
          DataFlow::PropWrite partsPropertyWrite, DataFlow::ArrayLiteralNode partsArray,
          DataFlow::ObjectLiteralNode partElement, DataFlow::Node pathValue
        |
          partsPropertyWrite = bindingAsObject.getAPropertyWrite("parts") and
          partsArray = partsPropertyWrite.getRhs().getALocalSource() and
          partElement = partsArray.getAnElement() and
          pathValue = partElement.getAPropertyWrite("path").getRhs() and
          if exists(pathValue.getALocalSource())
          then pathValue.getALocalSource() = bindingPath
          else pathValue = bindingPath
        )
    )
}

private newtype TBinding =
  /**
   * Any XML attribute that is assigned a binding string.
   * That is a string enclosed by curly braces.
   */
  TXmlPropertyBinding(XmlAttribute attribute, StaticBindingValue binding) {
    exists(BindingStringReader reader |
      attribute.getValue() = reader.getBindingString() and
      attribute.getLocation() = reader.getLocation() and
      binding = BindingStringParser::parseBinding(reader)
    ) and
    not attribute instanceof ContextBindingAttribute
  } or
  /**
   * Any XML attribute named "binding" that is assigned a binding string.
   * That is a string enclosed by curly braces.
   */
  TXmlContextBinding(ContextBindingAttribute attribute, StaticBindingValue binding) {
    exists(BindingStringReader reader|
      attribute.getValue() = reader.getBindingString() and
      attribute.getLocation() = reader.getLocation() and
      binding = BindingStringParser::parseBinding(reader)
    )
  } or
  /**
   * Any call to `new` where the an argument is a binding string, or
   * an object literal where the property `path` is assigned a value, or
   * an object literal where the propery `value` is assigned an object literal
   * with a property `parts` assigned a value.
   */
  TEarlyJavaScriptPropertyBinding(DataFlow::NewNode newNode, DataFlow::Node binding) {
    earlyPathPropertyBinding(newNode, binding, _)
  } or
  // Property binding via a call to `bindProperty` or `bindValue`.
  TLateJavaScriptPropertyBinding(
    LateJavaScriptPropertyBindingMethodCall bindProperty, DataFlow::Node binding
  ) {
    latePathBinding(bindProperty.asMethodCallNode(), binding, _)
  } or
  // Element binding via a call to `bindElement`.
  TLateJavaScriptContextBinding(
    BindElementMethodCallNode bindElementCall, DataFlow::Node binding
  ) {
    latePathBinding(bindElementCall, binding, _)
  } or
  // Json binding
  TJsonPropertyBinding(JsonValue value, string key, StaticBindingValue binding) {
    exists(JsonObject object, BindingStringReader reader|
      value = object.getPropValue(key) and
      value.getStringValue() = reader.getBindingString() and
      value.getLocation() = reader.getLocation() and
      binding = BindingStringParser::parseBinding(reader)
    )
  }

private BindingStringParser::BindingPath getABindingPath(BindingStringParser::Member member) {
  result = member.getBindingPath()
  or
  result = getABindingPath(member.getValue().(BindingStringParser::Object).getAMember())
  or
  result = getABindingPath(member.getValue().(BindingStringParser::Array).getAValue().(BindingStringParser::Object).getAMember())

}

private newtype TBindingPath =
  TStaticBindingPath(StaticBindingValue binding, BindingStringParser::BindingPath path) {
    binding.asBindingPath() = path
    or
    path = getABindingPath(binding.asObject().getAMember())
  }
  or
  TDynamicBindingPath(DataFlow::SourceNode binding, DataFlow::Node bindingPath) {
    (earlyPathPropertyBinding(_, binding, bindingPath)
    or
    latePathBinding(_, binding, bindingPath)) and
    not bindingPath.mayHaveStringValue(_)
  }

class BindingPath extends TBindingPath {
  string toString() {
    exists (BindingStringParser::BindingPath path |
      this = TStaticBindingPath(_, path) and
      result = path.toString()
    )
    or
    exists (DataFlow::Node pathValue |
      this = TDynamicBindingPath(_, pathValue) and
      if pathValue.mayHaveStringValue(_)
      then pathValue.mayHaveStringValue(result)
      else result = pathValue.toString()
    )
  }

  Binding getBinding() {
    result.getBindingPath() = this
  }
}

/**
 * A class to reason about UI5 bindings.
 * This is currently limited to:
 * - XML property bindings, including HTML
 * - XML context bindings
 * - JavaScript property bindings
 * - JavaScript context bindings
 * - JSON property bindings
 *
 * and supports property metadata bindings and composite bindings.
 * However, it does not support expression bindings.
 * Expression bindings support a subset of JavaScript and the embeding of model values
 * as described in the documentation at https://sapui5.hana.ondemand.com/sdk/#/topic/daf6852a04b44d118963968a1239d2c0.
 */
class Binding extends TBinding {
  string toString() {
    exists(XmlAttribute attribute, StaticBindingValue binding |
      this = TXmlPropertyBinding(attribute, binding) and
      result = "XML property binding: " + attribute.getName() + " to " + binding
    )
    or
    exists(ContextBindingAttribute attribute, StaticBindingValue binding |
      this = TXmlContextBinding(attribute, binding) and
      result = "XML context binding: " + attribute.getName() + " to " + binding
    )
    or
    exists(DataFlow::NewNode newNode, DataFlow::Node binding |
      this = TEarlyJavaScriptPropertyBinding(newNode, binding) and
      result =
        "Early JavaScript property binding: " + newNode.getArgument(0).toString() + " to " + binding
    )
    or
    exists(LateJavaScriptPropertyBindingMethodCall bindProperty, DataFlow::Node binding |
      this = TLateJavaScriptPropertyBinding(bindProperty, binding) and
      result =
        "Late JavaScript property binding: " + bindProperty.getPropertyName() + " to " + binding
    )
    or
    exists(BindElementMethodCallNode bindElementCall, DataFlow::Node binding |
      this = TLateJavaScriptContextBinding(bindElementCall, binding) and
      result =
        "JavaScript context binding: " + bindElementCall.getReceiver().toString() + " to " + binding
    )
    or
    exists(JsonValue value, string key, StaticBindingValue binding |
      this = TJsonPropertyBinding(value, key, binding) and
      result = "JSON property binding: " + key + " to " + binding
    )
  }

  Location getLocation() {
    exists(XmlAttribute attribute |
      this = TXmlPropertyBinding(attribute, _) and
      result = attribute.getLocation()
    )
    or
    exists(ContextBindingAttribute attribute |
      this = TXmlContextBinding(attribute, _) and
      result = attribute.getLocation()
    )
    or
    exists(DataFlow::Node binding |
      this = TEarlyJavaScriptPropertyBinding(_, binding) and
      result = binding.asExpr().getLocation()
    )
    or
    exists(DataFlow::Node binding |
      this = TLateJavaScriptPropertyBinding(_, binding) and
      result = binding.asExpr().getLocation()
    )
    or
    exists(DataFlow::Node binding |
      this = TLateJavaScriptContextBinding(_, binding) and
      result = binding.asExpr().getLocation()
    )
    or
    exists(JsonValue value, string key |
      this = TJsonPropertyBinding(value, key, _) and
      result = value.getLocation()
    )
  }

  BindingPath getBindingPath() {
    exists(StaticBindingValue bindingValue|
      this = TXmlPropertyBinding(_, bindingValue) and
      result = TStaticBindingPath(bindingValue, _)
      or
      this = TXmlContextBinding(_, bindingValue) and
      result = TStaticBindingPath(bindingValue, _)
      or
      this = TJsonPropertyBinding(_, _, bindingValue) and
      result = TStaticBindingPath(bindingValue, _)
    )
    or
    exists(DataFlow::Node bindingValue|
      this = TEarlyJavaScriptPropertyBinding(_, bindingValue) and
      result = TDynamicBindingPath(bindingValue, _)
      or
      this = TLateJavaScriptPropertyBinding(_, bindingValue) and
      result = TDynamicBindingPath(bindingValue, _)
      or
      this = TLateJavaScriptContextBinding(_, bindingValue) and
      result = TDynamicBindingPath(bindingValue, _)
    )
  }
}
