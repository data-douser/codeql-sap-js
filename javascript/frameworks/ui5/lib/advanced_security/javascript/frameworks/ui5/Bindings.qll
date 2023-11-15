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
  )
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

newtype TBinding =
  TXmlPropertyBinding(XmlAttribute attribute, BindingValue binding) {
    exists(StringBinding bindingString |
      attribute.getValue() = bindingString and
      binding = BindingStringParser::parseBinding(bindingString)
    ) and
    not attribute instanceof ContextBindingAttribute
  } or
  TXmlContextBinding(ContextBindingAttribute attribute, BindingValue binding) {
    exists(StringBinding bindingString |
      attribute.getValue() = bindingString and
      binding = BindingStringParser::parseBinding(bindingString)
    )
  } or
  TEarlyJavaScriptPropertyBinding(DataFlow::NewNode newNode, DataFlow::ValueNode binding) {
    exists(StringLiteral constantBinding |
      constantBinding.flow() = binding and constantBinding.getValue() instanceof StringBinding
    |
      newNode.getAnArgument().getALocalSource() = binding
    )
    or
    exists(DataFlow::ObjectLiteralNode objectBinding |
      objectBinding.asExpr().(ObjectExpr).getAProperty().getName() = "path" and
      binding = objectBinding
    |
      newNode.getAnArgument().getALocalSource() = objectBinding
    )
  } or
  TLateJavaScriptPropertyBinding(
    BindPropertyMethodCallNode bindProperty, DataFlow::ValueNode binding
  ) {
    exists(StringLiteral constantBinding |
      constantBinding.flow() = binding and constantBinding.getValue() instanceof StringBinding
    |
      bindProperty.getArgument(1).getALocalSource() = binding
    )
    or
    exists(DataFlow::ObjectLiteralNode objectBinding |
      objectBinding.asExpr().(ObjectExpr).getAProperty().getName() = "path" and
      binding = objectBinding
    |
      bindProperty.getArgument(1).getALocalSource() = objectBinding
    )
  } or
  TJavaScriptContextBinding(BindElementMethodCallNode bindElementCall, DataFlow::ValueNode binding) {
    bindElementCall.getMethodName() = "bindElement" and
    binding = bindElementCall.getArgument(0)
  }

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
    exists(BindPropertyMethodCallNode bindProperty, DataFlow::ValueNode binding |
      this = TLateJavaScriptPropertyBinding(bindProperty, binding) and
      result =
        "Late JavaScript property binding: " + bindProperty.getArgument(0).toString() + " to " +
          binding
    )
    or
    exists(BindElementMethodCallNode bindElementCall, DataFlow::ValueNode binding |
      this = TJavaScriptContextBinding(bindElementCall, binding) and
      result =
        "JavaScript context binding: " + bindElementCall.getReceiver().toString() + " to " + binding
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
      this = TJavaScriptContextBinding(_, binding) and
      result = binding.asExpr().getLocation()
    )
  }
}
