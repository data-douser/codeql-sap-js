import advanced_security.javascript.frameworks.cap.CDS
import advanced_security.javascript.frameworks.cap.CDL

abstract class CdlElementWithoutAuthn instanceof CdlElement {
  string toString() { result = super.toString() }

  Location getLocation() { result = super.getLocation() }
}

class CdlElementWithoutCdsAuthn extends CdlElementWithoutAuthn instanceof CdlElement {
  CdlElementWithoutCdsAuthn() { super.hasNoCdsAccessControl() }
}

class CdlServiceWithoutCdsAuthn extends CdlElementWithoutCdsAuthn instanceof CdlService { }

class CdlEntityWithoutCdsAuthn extends CdlElementWithoutCdsAuthn instanceof CdlEntity {
  CdlEntityWithoutCdsAuthn() {
    this.belongsToServiceWithNoAuthn() or
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
