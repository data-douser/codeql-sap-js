import javascript

private class ContextBindingAttribute extends XmlAttribute {
  ContextBindingAttribute() {
    this.getName() = "binding" and
    this.getNamespace().getUri() = "sap.m"
  }
}

class StringBinding extends string {
  bindingset[this]
  StringBinding() { this.matches("{%}") }
}

class BindPropertyMethodCallNode extends DataFlow::MethodCallNode {
  BindPropertyMethodCallNode() { this.getMethodName() = "bindProperty" }
}

class BindElementMethodCallNode extends DataFlow::MethodCallNode {
  BindElementMethodCallNode() { this.getMethodName() = "bindElement" }
}

newtype TBinding =
  TXmlPropertyBinding(XmlAttribute attribute, StringBinding binding) {
    attribute.getValue() = binding and
    binding.matches("{%}") and
    not attribute instanceof ContextBindingAttribute
  } or
  TXmlContextBinding(ContextBindingAttribute attribute, StringBinding binding) {
    attribute.getValue() = binding and
    binding.matches("{%}")
  } or
  TEarlyJavaScriptPropertyBinding(DataFlow::NewNode newNode, DataFlow::ValueNode binding) {
    exists(StringLiteral constantBinding |
      constantBinding.flow() = binding and constantBinding.getValue().matches("{%}")
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
      constantBinding.flow() = binding and constantBinding.getValue().matches("{%}")
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
    exists(XmlAttribute attribute, StringBinding binding |
      this = TXmlPropertyBinding(attribute, binding) and
      result = "XML property binding: " + attribute.getName() + " to " + binding
    )
    or
    exists(ContextBindingAttribute attribute, StringBinding binding |
      this = TXmlContextBinding(attribute, binding) and
      result = "XML context binding: " + attribute.getName() + " to " + binding
    )
    or
    exists(DataFlow::NewNode newNode, DataFlow::ValueNode binding |
      this = TEarlyJavaScriptPropertyBinding(newNode, binding) and
      result = "Early JavaScript property binding: " + newNode.getArgument(0).toString() + " to " + binding
    )
    or
    exists(BindPropertyMethodCallNode bindProperty, DataFlow::ValueNode binding |
      this = TLateJavaScriptPropertyBinding(bindProperty, binding) and
      result = "Late JavaScript property binding: " + bindProperty.getArgument(0).toString() + " to " + binding
    )
    or
    exists(BindElementMethodCallNode bindElementCall, DataFlow::ValueNode binding |
      this = TJavaScriptContextBinding(bindElementCall, binding) and
      result = "JavaScript context binding: " + bindElementCall.getReceiver().toString() + " to " + binding
    )
  }

  Location getLocation() {
    exists(XmlAttribute attribute|
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
