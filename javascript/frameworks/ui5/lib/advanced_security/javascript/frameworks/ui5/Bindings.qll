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

class BindingValue = BindingStringParser::Binding;

class StringBinding extends string {
  bindingset[this]
  StringBinding() { this = getBindingString() }
}

class BindPropertyMethodCallNode extends DataFlow::MethodCallNode {
  BindPropertyMethodCallNode() { this.getMethodName() = "bindProperty" }
}

class BindElementMethodCallNode extends DataFlow::MethodCallNode {
  BindElementMethodCallNode() { this.getMethodName() = "bindElement" }
}

class BindValueMethodCallNode extends DataFlow::MethodCallNode {
  BindValueMethodCallNode() { this.getMethodName() = "bindValue" }
}

newtype TLateJavaScriptPropertyBindingMethodCall =
  TBindProperty(BindPropertyMethodCallNode bindProperty) or
  TBindValue(BindValueMethodCallNode bindValue)

class LateJavaScriptPropertyBindingMethodCall extends TLateJavaScriptPropertyBindingMethodCall {
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

newtype TBinding =
  /**
   * Any XML attribute that is assigned a binding string.
   * That is a string enclosed by curly braces.
   */
  TXmlPropertyBinding(XmlAttribute attribute, BindingValue binding) {
    exists(StringBinding bindingString |
      attribute.getValue() = bindingString and
      binding = BindingStringParser::parseBinding(bindingString)
    ) and
    not attribute instanceof ContextBindingAttribute
  } or
  /**
   * Any XML attribute named "binding" that is assigned a binding string.
   * That is a string enclosed by curly braces.
   */
  TXmlContextBinding(ContextBindingAttribute attribute, BindingValue binding) {
    exists(StringBinding bindingString |
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
  TEarlyJavaScriptPropertyBinding(DataFlow::NewNode newNode, DataFlow::SourceNode binding) {
    // Property binding via a string binding
    exists(StringLiteral constantBinding |
      constantBinding = binding.asExpr() and constantBinding.getValue() instanceof StringBinding
    |
      newNode.getAnArgument().getALocalSource().(DataFlow::ObjectLiteralNode).getAPropertySource() =
        binding
    )
    or
    // Property binding via an object literal binding with property `path`.
    exists(DataFlow::ObjectLiteralNode objectBinding |
      objectBinding.asExpr().(ObjectExpr).getAProperty().getName() = "path" and
      binding = objectBinding
    |
      newNode.getAnArgument().getALocalSource() = objectBinding
    )
    or
    // Property binding with a composite binding
    exists(
      DataFlow::ObjectLiteralNode objectBinding, DataFlow::ObjectLiteralNode valueBinding,
      Property valueProperty
    |
      valueProperty = objectBinding.asExpr().(ObjectExpr).getAProperty() and
      valueProperty.getName() = "value" and
      valueProperty.getInit().flow() = valueBinding and
      valueBinding.asExpr().(ObjectExpr).getAProperty().getName() = "parts" and
      binding = objectBinding
    |
      newNode.getAnArgument().getALocalSource() = objectBinding
    )
  } or
  // Property binding via a call to `bindProperty` or `bindValue`.
  TLateJavaScriptPropertyBinding(
    LateJavaScriptPropertyBindingMethodCall bindProperty, DataFlow::ValueNode binding
  ) {
    bindProperty.getBinding() = binding
  } or
  // Element binding via a call to `bindElement`.
  TLateJavaScriptContextBinding(
    BindElementMethodCallNode bindElementCall, DataFlow::ValueNode binding
  ) {
    bindElementCall.getMethodName() = "bindElement" and
    bindElementCall.getArgument(0).getALocalSource() = binding
  } or
  // Json binding
  TJsonPropertyBinding(JsonValue value, string key, BindingValue binding) {
    exists(JsonObject object, StringBinding bindingString |
      value = object.getPropValue(key) and
      value.getStringValue() = bindingString and
      binding = BindingStringParser::parseBinding(bindingString)
    )
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
    exists(XmlAttribute attribute, BindingValue binding |
      this = TXmlPropertyBinding(attribute, binding) and
      result = "XML property binding: " + attribute.getName() + " to " + binding
    )
    or
    exists(ContextBindingAttribute attribute, BindingValue binding |
      this = TXmlContextBinding(attribute, binding) and
      result = "XML context binding: " + attribute.getName() + " to " + binding
    )
    or
    exists(DataFlow::NewNode newNode, DataFlow::ValueNode binding |
      this = TEarlyJavaScriptPropertyBinding(newNode, binding) and
      result =
        "Early JavaScript property binding: " + newNode.getArgument(0).toString() + " to " + binding
    )
    or
    exists(LateJavaScriptPropertyBindingMethodCall bindProperty, DataFlow::ValueNode binding |
      this = TLateJavaScriptPropertyBinding(bindProperty, binding) and
      result =
        "Late JavaScript property binding: " + bindProperty.getPropertyName() + " to " + binding
    )
    or
    exists(BindElementMethodCallNode bindElementCall, DataFlow::ValueNode binding |
      this = TLateJavaScriptContextBinding(bindElementCall, binding) and
      result =
        "JavaScript context binding: " + bindElementCall.getReceiver().toString() + " to " + binding
    )
    or
    exists(JsonValue value, string key, BindingValue binding |
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
    exists(DataFlow::ValueNode binding |
      this = TEarlyJavaScriptPropertyBinding(_, binding) and
      result = binding.asExpr().getLocation()
    )
    or
    exists(DataFlow::ValueNode binding |
      this = TLateJavaScriptPropertyBinding(_, binding) and
      result = binding.asExpr().getLocation()
    )
    or
    exists(DataFlow::ValueNode binding |
      this = TLateJavaScriptContextBinding(_, binding) and
      result = binding.asExpr().getLocation()
    )
    or
    exists(JsonValue value, string key |
      this = TJsonPropertyBinding(value, key, _) and
      result = value.getLocation()
    )
  }
}
