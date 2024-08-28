/**
 * @name Disabled XSJS CSRF protection
 * @description Disabling CSRF protection makes the application vulnerable to
 *              a Cross-Site Request Forgery (CSRF) attack.
 * @kind problem
 * @problem.severity error
 * @security-severity 8.8
 * @precision high
 * @id js/xsjs-disabled-csrf-protection
 * @tags security
 *       external/cwe/cwe-352
 */

import javascript
import advanced_security.javascript.frameworks.xsjs.Xsaccess

from JsonValue value
where
  value.getJsonFile() instanceof ExposedServiceAccessSpec and
  exists(JsonValue v |
    value = v.getPropValue(["prevent_xsrf", "csrfProtection"]) and
    value.getBooleanValue() = false
  )
select value, "CSRF vulnerability due to protection being disabled."
