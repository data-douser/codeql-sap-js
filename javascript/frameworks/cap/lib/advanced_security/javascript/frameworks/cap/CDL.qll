/**
 * A module to reason about CDL, the language to write specification of models of services, parsed into JSON.
 */

import javascript
import advanced_security.javascript.frameworks.cap.CDS

newtype CdlKind =
  CdlServiceKind(string value) { value = "service" } or
  CdlEntityKind(string value) { value = "entity" } or
  CdlEventKind(string value) { value = "event" } or
  CdlActionKind(string value) { value = "action" } or
  CdlFunctionKind(string value) { value = "function" }

/**
 * Any CDL element, including entities, event, actions, and more.
 */
class CdlDefinition extends JsonObject {
  CdlDefinition() { exists(JsonObject root | this = root.getPropValue("definitions")) }

  JsonObject getElement(string elementName) { result = this.getPropValue(elementName) }

  JsonObject getAnElement() { result = this.getElement(_) }
}

abstract class CdlElement extends JsonObject {
  CdlKind kind;
  string name;

  CdlElement() { exists(CdlDefinition definition | this = definition.getElement(name)) }

  /**
   * Gets the name of this CDL element.
   */
  string getName() { result = name }

  /**
   * Gets the kind of this CDL element.
   */
  CdlKind getKind() { result = kind }

  /**
   * Gets an annotation attached to this CDL element with the given name.
   */
  CdlAnnotation getAnnotation(string annotationName) {
    this = result.getQualifiedElement() and result.getName() = annotationName
  }

  /**
   * Gets an annotation attached to this CDL element.
   */
  CdlAnnotation getAnAnnotation() { result = this.getAnnotation(_) }

  CdlAttribute getAttribute(string attributeName) {
    result = this.getPropValue("elements").getPropValue(attributeName)
  }

  /**
   * Gets the `@restrict` annotation attached to this CDL element, if any.
   * Note that this excludes CDL events, as events emissions are not tied to
   * authentication or authorization.
   */
  RestrictAnnotation getRestrictAnnotation() { result = this.getAnnotation("restrict") }

  /**
   * Gets the `@requires` annotation attached to this CDL element, if any.
   * Note that this excludes CDL events, as events emissions are not tied to
   * authentication or authorization.
   */
  RequiresAnnotation getRequiresAnnotation() { result = this.getAnnotation("requires") }
}

class CdlService extends CdlElement {
  CdlService() { kind = CdlServiceKind(this.getPropStringValue("kind")) }

  override string getName() { result = name }

  override CdlKind getKind() { result = kind }

  CdlEntity getEntity(string entityName) {
    entityName = result.getName() and
    result.getFile() = this.getFile()
  }

  UserDefinedApplicationService getImplementation() {
    this.getFile().getStem() = result.getFile().getStem() + ".cds" and
    this.getFile().getParentContainer() = this.getFile().getParentContainer()
  }
}

class CdlEntity extends CdlElement {
  CdlEntity() { kind = CdlEntityKind(this.getPropStringValue("kind")) }

  override string getName() { result = name }

  override CdlKind getKind() { result = kind }

  predicate isRestrictedOnlyToSomeRole(string eventName) {
    exists(RestrictCondition restrictCondition |
      restrictCondition = this.getRestrictAnnotation().getARestrictCondition() and
      exists(restrictCondition.getToClause())
    |
      restrictCondition.grants(eventName) and
      restrictCondition.getToClause() != "any"
    )
  }
}

class CdlEvent extends CdlElement {
  CdlEvent() { kind = CdlEventKind(this.getPropStringValue("kind")) }

  string getBasename() { result = name.splitAt(".", count(name.indexOf("."))) }

  override string getName() { result = name }

  override CdlKind getKind() { result = kind }
}

class CdlAction extends CdlElement {
  CdlAction() { kind = CdlActionKind(this.getPropStringValue("kind")) }
}

class CdlFunction extends CdlElement {
  CdlFunction() { kind = CdlFunctionKind(this.getPropStringValue("kind")) }

  JsonObject getReturns() { result = this.getPropValue("returns") }
}

class CdlAttribute extends JsonObject {
  string name;

  CdlAttribute() {
    exists(CdlElement entity | this = entity.getPropValue("elements").getPropValue(name))
  }

  string getType() { result = this.getPropStringValue("type") }

  int getLength() { result = this.getPropValue("length").(JsonPrimitiveValue).getIntValue() }
}

class CdlAnnotation extends JsonValue {
  string annotationName;
  CdlElement element;

  CdlAnnotation() {
    this = element.getPropValue(annotationName) and
    annotationName.charAt(0) = "@"
  }

  /**
   * Gets the name of this annotation, without the leading `@` character.
   */
  string getName() { "@" + result = annotationName }

  /**
   * Gets the CDL Element that this annotation is attached to.
   */
  CdlElement getQualifiedElement() { result = element }
}

class ProtocolAnnotation extends CdlAnnotation {
  ProtocolAnnotation() {
    this.getQualifiedElement() instanceof CdlService and this.getName() = "protocol"
  }

  string getAnExposedProtocol() {
    /* e.g. @protocol: 'odata' */
    result = this.(JsonString).getValue()
    or
    /* e.g. @protocol: ['odata', 'rest', 'graphql'] */
    result = this.(JsonArray).getElementStringValue(_)
    or
    /* e.g. @protocol: [{ kind: 'odata', path: 'some/path' }] */
    result = this.(JsonArray).getElementValue(_).(JsonObject).getPropStringValue("kind")
  }
}

class CdsFile extends File {
  CdsFile() { exists(CdlElement element | this = element.getJsonFile()) }
}

class RestrictAnnotation extends CdlAnnotation, JsonArray {
  RestrictAnnotation() { this.getName() = "restrict" }

  RestrictCondition getARestrictCondition() { result = this.getElementValue(_) }
}

class RestrictCondition extends JsonObject {
  RestrictCondition() { exists(RestrictAnnotation restrict | this = restrict.getElementValue(_)) }

  predicate grants(string eventName) {
    exists(JsonValue grantClause | grantClause = this.getGrantClause() |
      grantClause.(JsonString).getValue() = eventName or
      grantClause.(JsonArray).getElementValue(_).(JsonString).getValue() = eventName
    )
  }

  predicate grantsToAnyone(string eventName) {
    this.grants(eventName) and
    (
      this.getToClause() = "any"
      or
      /* The default value is `"any"`. */
      not exists(this.getToClause())
    )
  }

  JsonValue getGrantClause() { result = this.getPropValue("grant") }

  string getToClause() { result = this.getPropStringValue("to") }

  string getWhereClause() { result = this.getPropStringValue("where") }

  string getWhereClauseParsed() { result = this.getPropStringValue("_where") }
}

class RequiresAnnotation extends CdlAnnotation {
  RequiresAnnotation() { this.getName() = "requires" }

  string getRequiredRole() {
    result = this.(JsonArray).getElementStringValue(_) or
    result = this.getStringValue()
  }
}