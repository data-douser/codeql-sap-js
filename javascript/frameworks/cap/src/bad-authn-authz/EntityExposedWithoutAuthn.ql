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

from CdlElementWithoutAuthn cdlElementWithoutAuthn
select cdlElementWithoutAuthn, "$@ is exposed without any authentication",
  cdlElementWithoutAuthn, "This CDS definition"
