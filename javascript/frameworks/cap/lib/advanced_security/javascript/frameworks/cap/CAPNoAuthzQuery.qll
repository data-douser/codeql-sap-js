import advanced_security.javascript.frameworks.cap.CDS
import advanced_security.javascript.frameworks.cap.CDL

abstract class CdlElementWithoutAuthn instanceof CdlElement {
  string toString() { result = super.toString() }
}

class CdlElementWithoutCdsAuthn extends CdlElementWithoutAuthn instanceof CdlElement {
  CdlElementWithoutCdsAuthn() { super.hasNoCdsAccessControl() }
}

class CdlServiceWithoutCdsAuthn extends CdlElementWithoutCdsAuthn instanceof CdlService { }

class CdlEntityWithoutCdsAuthn extends CdlElementWithoutCdsAuthn instanceof CdlEntity {
  CdlEntityWithoutCdsAuthn() {
    any() // TODO: inherits, belongsToAuthenticatedService
  }
}

class CdlActionWithoutCdsAuthn extends CdlElementWithoutCdsAuthn instanceof CdlAction {
  CdlActionWithoutCdsAuthn() {
    any() // TODO: belongsToAuthenticatedService
  }
}

class CdlFunctionWithoutCdsAuthn extends CdlElementWithoutCdsAuthn instanceof CdlAction {
  CdlFunctionWithoutCdsAuthn() {
    any() // TODO: belongsToAuthenticatedService
  }
}
