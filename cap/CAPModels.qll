private import javascript
private import DataFlow

predicate isService() {
  any() // TODO
}

predicate isRequest() {
  any() // TODO
}

private ModuleImportNode isCdsInner(TypeTracker t) {
  t.start() and
  result.getPath() = "@sap/cds"
  or
  exists(TypeTracker t2 | result = isCdsInner(t2).track(t2, t))
}

predicate isCds(ModuleImportNode node) { node = isCdsInner(TypeTracker::end()) }

/**
 * ```js
 * const cds = require('@sap/cds')
 * ```
 */
class CDSFacade extends ModuleImportNode {
  CDSFacade() { isCds(this) }
}
