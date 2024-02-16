/**
 * A module to reason about CDL, the language to write specification of models of services, parsed into JSON.
 */

import javascript

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
    /* WARNING: Hacky! */
    entityName.splitAt(".", 0) = name
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

class CdlAttribute extends JsonObject {
  string name;

  CdlAttribute() {
    exists(CdlElement entity | this = entity.getPropValue("elements").getPropValue(name))
  }

  string getType() { result = this.getPropStringValue("type") }

  int getLength() { result = this.getPropValue("length").(JsonPrimitiveValue).getIntValue() }
}
