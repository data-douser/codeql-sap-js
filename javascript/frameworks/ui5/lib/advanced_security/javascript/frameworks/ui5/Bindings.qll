import javascript
import advanced_security.javascript.frameworks.ui5.BindingStringParser as MakeBindingStringParser

private class ContextBindingAttribute extends XmlAttribute {
  ContextBindingAttribute() { this.getName() = "binding" }
}

private string getBindingString() {
  result.matches("{%}") and
  (
    exists(StringLiteral stringLit | result = stringLit.getValue())
    or
    exists(XmlAttribute attribute | result = attribute.getValue())
    or
    exists(JsonObject object | result = object.getPropStringValue(_))
  )
  or
  any(BindPropertyMethodCallNode call)
      .getArgument(1)
      .getALocalSource()
      .asExpr()
      .(StringLiteral)
      .getValue() = result
  or
  any(BindElementMethodCallNode call)
      .getArgument(0)
      .getALocalSource()
      .asExpr()
      .(StringLiteral)
      .getValue() = result
}

private module BindingStringParser =
  MakeBindingStringParser::BindingStringParser<getBindingString/0>;

private class StaticBindingValue = BindingStringParser::Binding;

class BindingString extends string {
  bindingset[this]
  BindingString() { this = getBindingString() }
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

private predicate earlyPathPropertyBinding(DataFlow::NewNode newNode, DataFlow::SourceNode binding, DataFlow::Node bindingPath) {
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
    exists(
      DataFlow::ObjectLiteralNode valueBinding,
      Property valueProperty,
      Property partsProperty,
      DataFlow::ArrayLiteralNode partsArray,
      DataFlow::ObjectLiteralNode partElement,
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

private predicate latePathBinding(DataFlow::MethodCallNode bindingCall, DataFlow::SourceNode binding, DataFlow::Node bindingPath) {
  (
    exists(LateJavaScriptPropertyBindingMethodCall lateJavaScriptPropertyBindingMethodCall|
    bindingCall = lateJavaScriptPropertyBindingMethodCall.asMethodCallNode() and
    binding = lateJavaScriptPropertyBindingMethodCall.getBinding())
    or
    exists(BindElementMethodCallNode bindElementMethodCall |
    bindingCall = bindElementMethodCall and
    binding = bindElementMethodCall.getArgument(0).getALocalSource())
  )
  and
  (
    exists(Property path, DataFlow::Node pathValue |
      binding.asExpr().(ObjectExpr).getPropertyByName("path") = path and
      pathValue = path.getInit().flow()
    |
      if exists(pathValue.getALocalSource())
      then pathValue.getALocalSource() = bindingPath
      else pathValue = bindingPath // e.g., path: "/" + someVar
    )
    or
    exists(
      DataFlow::ObjectLiteralNode valueBinding,
      Property valueProperty,
      Property partsProperty,
      DataFlow::ArrayLiteralNode partsArray,
      DataFlow::ObjectLiteralNode partElement,
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
    )
  )
}

private newtype TBinding =
  /**
   * Any XML attribute that is assigned a binding string.
   * That is a string enclosed by curly braces.
   */
  TXmlPropertyBinding(XmlAttribute attribute, StaticBindingValue binding) {
    exists(BindingString bindingString |
      attribute.getValue() = bindingString and
      binding = BindingStringParser::parseBinding(bindingString)
    ) and
    not attribute instanceof ContextBindingAttribute
  } or
  /**
   * Any XML attribute named "binding" that is assigned a binding string.
   * That is a string enclosed by curly braces.
   */
  TXmlContextBinding(ContextBindingAttribute attribute, StaticBindingValue binding) {
    exists(BindingString bindingString |
      attribute.getValue() = bindingString and
      binding = BindingStringParser::parseBinding(bindingString)
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
    exists(JsonObject object, BindingString bindingString |
      value = object.getPropValue(key) and
      value.getStringValue() = bindingString and
      binding = BindingStringParser::parseBinding(bindingString)
    )
  }

private BindingStringParser::BindingPath getABindingPath(BindingStringParser::Member member) {
  result = member.getBindingPath()
  or
  result = getABindingPath(member.getValue().(BindingStringParser::Object).getAMember())

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
    exists(StaticBindingValue bindingValue|
      result = TXmlPropertyBinding(_, bindingValue) and
      this = TStaticBindingPath(bindingValue, _)
      or
      result = TXmlContextBinding(_, bindingValue) and
      this = TStaticBindingPath(bindingValue, _)
      or
      result = TJsonPropertyBinding(_, _, bindingValue) and
      this = TStaticBindingPath(bindingValue, _)
    )
    or
    exists(DataFlow::Node bindingValue|
      result = TEarlyJavaScriptPropertyBinding(_, bindingValue) and
      this = TDynamicBindingPath(bindingValue, _)
      or
      result = TLateJavaScriptPropertyBinding(_, bindingValue) and
      this = TDynamicBindingPath(bindingValue, _)
      or
      result = TLateJavaScriptContextBinding(_, bindingValue) and
      this = TDynamicBindingPath(bindingValue, _)
    )
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
    result.getBinding() = this
  }
}
