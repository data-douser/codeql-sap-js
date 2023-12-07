/**
 * A module to reason about UI5 bindings.
 */
import javascript
import advanced_security.javascript.frameworks.ui5.BindingStringParser as MakeBindingStringParser

private class ContextBindingAttribute extends XmlAttribute {
  ContextBindingAttribute() { this.getName() = "binding" }
}

/**
 * A type representing the various ways a literal binding can be specified.
 */
// TODO: add support for binding strings in strings such as `description: "Some {/description}"`
private newtype TBindingString =
  TBindingStringFromLiteral(StringLiteral stringLiteral) { stringLiteral.getValue().matches("{%}") } or
  TBindingStringFromXmlAttribute(XmlAttribute attribute) { attribute.getValue().matches("{%}") } or
  TBindingStringFromJsonProperty(JsonObject object, string propertyName) {
    object.getPropStringValue(propertyName).matches("{%}")
  } or
  TBindingStringFromBindElementMethodCall(BindElementMethodCallNode bindElement) {
    bindElement.getArgument(0).getALocalSource().asExpr().(StringLiteral).getValue().matches("{%}")
  } or
  TBindingStringFromBindPropertyMethodCall(BindPropertyMethodCallNode bindProperty) {
    bindProperty.getArgument(1).getALocalSource().asExpr().(StringLiteral).getValue().matches("{%}")
  }

/**
 * A binding string reader used by the binding string parser.
 * This extends the type TBindingString so we can parse all the identified literal binding strings.
 */
private class BindingStringReader extends TBindingString {
  string toString() { result = this.getBindingString() }

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

/**
 * A binding string parser instantiated with the binding string reader.
 */
private module BindingStringParser =
  MakeBindingStringParser::BindingStringParser<BindingStringReader>;

/**
 * A parsed binding string whoes content could be statically determined.
 */
private class StaticBindingValue = BindingStringParser::Binding;

/**
 * A binding string as identified by the binding string reader.
 */
class BindingString extends string {
  bindingset[this]
  BindingString() { this = any(BindingStringReader reader).getBindingString() }
}

/**
 * A `bindProperty` method call that represents a late JavaScript property binding.
 * It is late because the binding happens after the control is created.
 */
private class BindPropertyMethodCallNode extends LateJavaScriptPropertyBinding,
  DataFlow::MethodCallNode
{
  BindPropertyMethodCallNode() { this.getMethodName() = "bindProperty" }

  override DataFlow::Node getBinding() { result = this.getArgument(1) }

  override DataFlow::Node getPropertyNameNode() { result = this.getArgument(0) }

  override string getPropertyName() {
    result = this.getPropertyNameNode().getALocalSource().getStringValue()
  }

  override DataFlow::Node getTarget() { result = this.getReceiver() }
}

private class BindElementMethodCallNode extends DataFlow::MethodCallNode {
  BindElementMethodCallNode() { this.getMethodName() = "bindElement" }
}

private class BindValueMethodCallNode extends LateJavaScriptPropertyBinding,
  DataFlow::MethodCallNode
{
  BindValueMethodCallNode() { this.getMethodName() = "bindValue" }

  override DataFlow::Node getBinding() { result = this.getArgument(1) }

  override DataFlow::Node getPropertyNameNode() { none() }

  override string getPropertyName() { result = "value" }

  override DataFlow::Node getTarget() { result = this.getReceiver() }
}

/**
 * A class representing all the ways a property can be bounded in JavaScript after the
 * control has been created.
 */
abstract private class LateJavaScriptPropertyBinding extends DataFlow::Node {
  abstract DataFlow::Node getBinding();

  abstract DataFlow::Node getPropertyNameNode();

  abstract string getPropertyName();

  abstract DataFlow::Node getTarget();

  override string toString() {
    if exists(getPropertyName())
    then
      result =
        "Binding property " + getPropertyName() + " of " + getTarget().toString() + " to " +
          getBinding().toString()
    else
      result =
        "Binding property " + getPropertyNameNode().toString() + "of " + getTarget().toString() +
          " to " + getBinding().toString()
  }
}

/**
 * Holds if the `newNode` parameter representing a `new ...` expression creates an instance
 * that receives a binding `binding` with a binding path `bindingPath`.
 */
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

/**
 * Holds if the `bindingCall` parameter representing a method call that binds a property or element
 * that receives a binding `binding` with a binding path `bindingPath`.
 */
private predicate latePathBinding(
  DataFlow::MethodCallNode bindingCall, DataFlow::SourceNode binding, DataFlow::Node bindingPath
) {
  (
    exists(LateJavaScriptPropertyBinding lateJavaScriptPropertyBinding |
      bindingCall = lateJavaScriptPropertyBinding and
      binding = lateJavaScriptPropertyBinding.getBinding()
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

/**
 * A type reprensenting the various UI5 bindings.
 */
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
    exists(BindingStringReader reader |
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
  TLateJavaScriptPropertyBinding(LateJavaScriptPropertyBinding bindProperty, DataFlow::Node binding) {
    latePathBinding(bindProperty, binding, _)
  } or
  // Element binding via a call to `bindElement`.
  TLateJavaScriptContextBinding(BindElementMethodCallNode bindElementCall, DataFlow::Node binding) {
    latePathBinding(bindElementCall, binding, _)
  } or
  // Json binding
  TJsonPropertyBinding(JsonObject object, string key, StaticBindingValue binding) {
    exists(JsonValue value, BindingStringReader reader |
      value = object.getPropValue(key) and
      value.getStringValue() = reader.getBindingString() and
      value.getLocation() = reader.getLocation() and
      binding = BindingStringParser::parseBinding(reader)
    )
  }

/**
 * Recursively gets a binding path from a binding.
 */
private BindingStringParser::BindingPath getABindingPath(BindingStringParser::Member member) {
  result = member.getBindingPath()
  or
  result = getABindingPath(member.getValue().(BindingStringParser::Object).getAMember())
  or
  result =
    getABindingPath(member
          .getValue()
          .(BindingStringParser::Array)
          .getAValue()
          .(BindingStringParser::Object)
          .getAMember())
}

/**
 * A type representing the various binding paths.
 */
private newtype TBindingPath =
  TStaticBindingPath(StaticBindingValue binding, BindingStringParser::BindingPath path) {
    binding.asBindingPath() = path
    or
    path = getABindingPath(binding.asObject().getAMember())
  } or
  TDynamicBindingPath(DataFlow::SourceNode binding, DataFlow::Node bindingPath) {
    (
      earlyPathPropertyBinding(_, binding, bindingPath)
      or
      latePathBinding(_, binding, bindingPath)
    ) and
    not bindingPath.mayHaveStringValue(_)
  }

/**
 * A class representing a binding path.
**/
class BindingPath extends TBindingPath {
  string toString() {
    exists(BindingStringParser::BindingPath path |
      this = TStaticBindingPath(_, path) and
      result = path.toString()
    )
    or
    exists(DataFlow::Node pathValue |
      this = TDynamicBindingPath(_, pathValue) and
      if pathValue.mayHaveStringValue(_)
      then pathValue.mayHaveStringValue(result)
      else result = pathValue.toString()
    )
  }

  /**
   * Get the string representation of a binding path if it can be statically determined.
   */
  string asString() {
    exists(BindingStringParser::BindingPath path |
      this = TStaticBindingPath(_, path) and
      result = path.toString()
    )
  }

  Location getLocation() {
    exists(BindingStringParser::BindingPath path |
      this = TStaticBindingPath(_, path) and
      result = path.getLocation()
    )
    or
    exists(DataFlow::Node pathValue |
      this = TDynamicBindingPath(_, pathValue) and
      result = pathValue.asExpr().getLocation()
    )
  }

  string getModelName() {
    exists(BindingStringParser::BindingPath path |
      this = TStaticBindingPath(_, path) and
      result = path.getModel()
    )
  }

  predicate isRelative() {
    exists(BindingStringParser::BindingPath path |
      this = TStaticBindingPath(_, path) and
      path.isRelative()
    )
  }

  predicate isAbsolute() {
    exists(BindingStringParser::BindingPath path |
      this = TStaticBindingPath(_, path) and
      path.isAbsolute()
    )
  }

  Binding getBinding() { result.getBindingPath() = this }
}

/**
 * A type representing the various locations whose values can be bound.
 */
private newtype TBindingTarget =
  TXmlPropertyBindingTarget(XmlAttribute target, Binding binding) {
    binding = TXmlPropertyBinding(target, _)
  } or
  TXmlContextBindingTarget(ContextBindingAttribute target, Binding binding) {
    binding = TXmlContextBinding(target, _)
  } or
  TLateJavaScriptBindingTarget(DataFlow::Node target, Binding binding) {
    exists(DataFlow::MethodCallNode call |
      binding = TLateJavaScriptContextBinding(call, _) and
      call.getReceiver() = target
    )
    or
    exists(LateJavaScriptPropertyBinding propertyBinding |
      binding = TLateJavaScriptPropertyBinding(propertyBinding, _) and
      target = propertyBinding.getTarget()
    )
  } or
  TJsonPropertyBindingTarget(JsonObject target, string key, Binding binding) {
    binding = TJsonPropertyBinding(target, key, _)
  }

/**
 * A class representing a binding target, that is, a location whose value can be bound.
 */
class BindingTarget extends TBindingTarget {
  string toString() {
    exists(XmlAttribute attribute |
      this = TXmlPropertyBindingTarget(attribute, _) and
      result = attribute.getName()
    )
    or
    exists(ContextBindingAttribute attribute |
      this = TXmlContextBindingTarget(attribute, _) and
      result = attribute.getName()
    )
    or
    exists(DataFlow::Node target |
      this = TLateJavaScriptBindingTarget(target, _) and
      result = target.toString()
    )
    or
    exists(JsonObject target, string key |
      this = TJsonPropertyBindingTarget(target, key, _) and
      result = target.toString() + "." + key
    )
  }

  XmlAttribute asXmlAttribute() {
    exists(XmlAttribute target |
      (
        this = TXmlPropertyBindingTarget(target, _)
        or
        this = TXmlContextBindingTarget(target, _)
      ) and
      result = target
    )
  }

  JsonObject asJsonObject() {
    exists(JsonObject target |
      this = TJsonPropertyBindingTarget(target, _, _) and
      result = target
    )
  }

  DataFlow::Node asDataFlowNode() {
    exists(DataFlow::Node target |
      this = TLateJavaScriptBindingTarget(target, _) and
      result = target
    )
  }

  Location getLocation() {
    exists(XmlAttribute attribute |
      this = TXmlPropertyBindingTarget(attribute, _) and
      result = attribute.getLocation()
    )
    or
    exists(ContextBindingAttribute attribute |
      this = TXmlContextBindingTarget(attribute, _) and
      result = attribute.getLocation()
    )
    or
    exists(DataFlow::Node target |
      this = TLateJavaScriptBindingTarget(target, _) and
      result = target.asExpr().getLocation()
    )
    or
    exists(JsonObject target, string key |
      this = TJsonPropertyBindingTarget(target, key, _) and
      result = target.getLocation()
    )
  }

  Binding getBinding() {
    this = TXmlPropertyBindingTarget(_, result) or
    this = TXmlContextBindingTarget(_, result) or
    this = TLateJavaScriptBindingTarget(_, result) or
    this = TJsonPropertyBindingTarget(_, _, result)
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
    exists(LateJavaScriptPropertyBinding bindProperty, DataFlow::Node binding |
      this = TLateJavaScriptPropertyBinding(bindProperty, binding) and
      if exists(bindProperty.getPropertyName())
      then
        result =
          "Late JavaScript property binding: " + bindProperty.getPropertyName() + " to " + binding
      else
        result =
          "Late JavaScript property binding: " + bindProperty.getPropertyNameNode().toString() +
            " to " + binding
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
    exists(StaticBindingValue bindingValue |
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
    exists(DataFlow::Node bindingValue |
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

  BindingTarget getBindingTarget() { result.getBinding() = this }
}
