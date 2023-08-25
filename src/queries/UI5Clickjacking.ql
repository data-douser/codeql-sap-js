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
import semmle.javascript.RestrictedLocations
private import models.UI5

class HtmlStartTag extends HTML::DocumentElement, FirstLineOf {
  HtmlStartTag() {
    exists(UI5::Project p | this.getFile().(FirstLineOf).getFile() = p.getMainHTML())
  }
}

newtype TAlertLocation =
  TFrameOptions(FrameOptions frameOptions) or
  THtmlStartTag(HtmlStartTag htmlStartTag)

class AlertLocation extends TAlertLocation {
  FrameOptions asFrameOptions() { this = TFrameOptions(result) }

  HtmlStartTag asHtmlStartTag() { this = THtmlStartTag(result) }

  string toString() {
    result = this.asFrameOptions().toString() or
    result = this.asHtmlStartTag().toString()
  }

  predicate hasLocationInfo(string path, int sl, int sc, int el, int ec) {
    this.asFrameOptions().getLocation().hasLocationInfo(path, sl, sc, el, ec)
    or
    this.asHtmlStartTag().hasLocationInfo(path, sl, sc, el, ec)
  }
}

from AlertLocation alert, string message
where
  exists(FrameOptions frameOptions | frameOptions.allowsAllOriginEmbedding() |
    alert.asFrameOptions() = frameOptions and
    message =
      "Possible clickjacking vulnerability due to " + frameOptions.toString() +
        " being set to `allow`."
  )
  or
  exists(UI5::Project p | thereIsNoFrameOptionSet(p) |
    alert.asHtmlStartTag().getFile() = p.getMainHTML() and
    message = "Possible clickjacking vulnerability due to missing frame options."
  )
select alert, message
