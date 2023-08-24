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
    this.getFile() =
      any(FirstLineOf firstLineOf | firstLineOf.getFile() = any(UI5::Project p).getMainHTML())
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
    /* This is a FrameOption */
    exists(Location location | location = this.asFrameOptions().getLocation() |
      path = location.getFile().getAbsolutePath() and
      sl = location.getStartLine() and
      sc = location.getStartColumn() and
      el = location.getEndLine() and
      ec = location.getEndColumn()
    )
    or
    /* This is an HtmlStartTag */
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
    exists(HTML::HtmlFile file, HtmlStartTag doc |
      file = p.getMainHTML() and
      doc.getFile() = file and
      alert.asHtmlStartTag() = doc
    ) and
    message = "Possible clickjacking vulnerability due to missing frame options."
  )
select alert, message
