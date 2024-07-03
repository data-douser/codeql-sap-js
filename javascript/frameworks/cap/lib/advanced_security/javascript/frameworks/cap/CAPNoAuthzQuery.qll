import advanced_security.javascript.frameworks.cap.CDS
import advanced_security.javascript.frameworks.cap.CDL

abstract class CdlElementWithoutAuthn instanceof CdlElement {
  string toString() { result = super.toString() }

  Location getLocation() { result = super.getLocation() }
}

abstract class CdlElementWithoutCdsAuthn extends CdlElementWithoutAuthn instanceof CdlElement {
  CdlElementWithoutCdsAuthn() { this.hasNoCdsAccessControl() }
}

class CdlServiceWithoutCdsAuthn extends CdlElementWithoutCdsAuthn instanceof CdlService { }

class CdlEntityWithoutCdsAuthn extends CdlElementWithoutCdsAuthn instanceof CdlEntity {
  CdlEntityWithoutCdsAuthn() {
    this.belongsToServiceWithNoAuthn()
    or
    exists(CdlEntityWithoutCdsAuthn otherCdlEntityWithoutCdsAuthn |
      this.inherits(otherCdlEntityWithoutCdsAuthn)
    )
  }
}

class CdlActionWithoutCdsAuthn extends CdlElementWithoutCdsAuthn instanceof CdlAction {
  CdlActionWithoutCdsAuthn() { this.belongsToServiceWithNoAuthn() }
}

class CdlFunctionWithoutCdsAuthn extends CdlElementWithoutCdsAuthn instanceof CdlAction {
  CdlFunctionWithoutCdsAuthn() { this.belongsToServiceWithNoAuthn() }
}

abstract class CdlElementWithoutJsAuthn extends CdlElementWithoutAuthn instanceof CdlElement { }

class CdlServiceWithoutJsAuthn extends CdlElementWithoutJsAuthn instanceof CdlService {
  // TODO
}

class CdlEntityWithoutJsAuthn extends CdlElementWithoutJsAuthn instanceof CdlEntity {
  // TODO
}

class CdlActionWithoutJsAuthn extends CdlElementWithoutJsAuthn instanceof CdlAction {
  // TODO
}

class CdlFunctionWithoutJsAuthn extends CdlElementWithoutJsAuthn instanceof CdlFunction {
  // TODO
}