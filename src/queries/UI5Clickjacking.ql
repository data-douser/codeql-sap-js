/**
 * @name Clickjacking
 * @description The absence of frame options allows for clickjacking.
 * @kind problem
 * @problem.severity error
 * @security-severity 6.1
 * @precision low
 * @id js/ui5-clickjacking
 * @tags security
 *      external/cwe/cwe-451
 */

import javascript
import models.UI5HTML

from Location location, string message
where
  exists(FrameOptions frameOptions | frameOptions.allowsAllOriginEmbedding() |
    location = frameOptions.getLocation() and
    message = "Possible clickjacking vulnerability due to " + frameOptions.toString() + " being set to `allow`."
  )
  or
  thereIsNoFrameOptionSet() and
  location = any(HTML::HtmlFile file | file.getBaseName() = "index.html").getLocation() and
  message = "Possible clickjacking vulnerability due to missing frame options."
select location, message
