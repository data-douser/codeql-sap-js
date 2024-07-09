/**
 * @name Entity exposed without authentication
 * @description TODO
 * @kind problem
 * @problem.severity warning
 * @security-severity 6
 * @precision high
 * @id js/entity-exposed-without-authentication
 * @tags security
 */

import advanced_security.javascript.frameworks.cap.CAPNoAuthzQuery

string getClickableText(CdlElement cdlElement) {
  cdlElement instanceof CdlService and result = "CDS service"
  or
  cdlElement instanceof CdlEntity and result = "CDS entity"
  or
  cdlElement instanceof CdlAction and result = "CDS action"
  or
  cdlElement instanceof CdlFunction and result = "CDS function"
}

from CdlElement cdlElement
where
  cdlElement instanceof CdlElementWithoutJsAuthn and
  cdlElement instanceof CdlElementWithoutCdsAuthn
select cdlElement, "This $@ is exposed without any authentication.", cdlElement, getClickableText(cdlElement)
