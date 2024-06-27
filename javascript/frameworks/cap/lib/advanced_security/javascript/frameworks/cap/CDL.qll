/**
 * A module to reason about CDL, the language to write specification of models of services, parsed into JSON.
 */

import javascript
import advanced_security.javascript.frameworks.cap.CDS

newtype CdlKind =
  Service(string value) { value = "service" } or
  Entity(string value) { value = "entity" } or
  Event(string value) { value = "event" } or
  Action(string value) { value = "action" }

/**
 * Any CDL element, including entities, event, actions, and more.
 */
class CdlDefinition extends JsonObject {
  CdlDefinition() { exists(JsonObject root | this = root.getPropValue("definitions")) }

  JsonObject getElement(string elementName) { result = this.getPropValue(elementName) }

  JsonObject getAnElement() { result = this.getElement(_) }
}

abstract class CdlElement extends JsonObject {
  abstract string getName();

  abstract CdlKind getKind();

  CdlAnnotation getAnnotation(string annotationName) {
    this = result.getQualifiedElement() and result.getName() = annotationName
  }

  CdlAnnotation getAnAnnotation() { result = this.getAnnotation(_) }
}

class CdlService extends CdlElement {
  string name;
  CdlKind kind;

  CdlService() {
    exists(CdlDefinition definition |
      this = definition.getElement(name) and
      kind = Service(this.getPropStringValue("kind"))
    )
  }

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
  string name;
  CdlKind kind;

  CdlEntity() {
    exists(CdlDefinition definition |
      this = definition.getElement(name) and
      kind = Entity(this.getPropStringValue("kind"))
    )
  }

  override string getName() { result = name }

  override CdlKind getKind() { result = kind }

  CdlAttribute getAttribute(string attributeName) {
    result = this.getPropValue("elements").getPropValue(attributeName)
  }

  RestrictAnnotation getRestrictAnnotation() { result = this.getAnnotation("restrict") }

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
  string name;
  CdlKind kind;

  CdlEvent() {
    exists(CdlDefinition definition |
      this = definition.getElement(name) and
      kind = Event(this.getPropStringValue("kind"))
    )
  }

  string getBasename() { result = name.splitAt(".", count(name.indexOf("."))) }

  override string getName() { result = name }

  override CdlKind getKind() { result = kind }

  CdlAttribute getAttribute(string attributeName) {
    result = this.getPropValue("elements").getPropValue(attributeName)
  }
}

class CdlAction extends CdlElement {
  string name;
  CdlKind kind;

  CdlAction() {
    exists(CdlDefinition definition |
      this = definition.getElement(name) and
      kind = Action(this.getPropStringValue("kind"))
    )
  }

  override string getName() { result = name }

  override CdlKind getKind() { result = kind }

  CdlAttribute getAttribute(string attributeName) {
    result = this.getPropValue("elements").getPropValue(attributeName)
  }
}

// /* TODO */
// class CdlFunction extends CdlElement {}
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
  RestrictAnnotation() {
    this.getQualifiedElement() instanceof CdlEntity and
    this.getName() = "restrict"
  }

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
