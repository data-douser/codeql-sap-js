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

from FrameOptions frameOptions
where frameOptions.allowsAllOriginEmbedding() or thereIsNoFrameOptionSet()
select frameOptions, "Clickjacking vulnerability due to $@.", frameOptions, frameOptions.toString()
