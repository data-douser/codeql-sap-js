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
private import models.UI5

class IndexHtmlElement extends HTML::DocumentElement {
  IndexHtmlElement() { this.getFile() = any(UI5::Project p).getMainHTML() }

  predicate hasLocationInfo(string path, int sl, int sc, int el, int ec) {
    exists(Location loc | loc = this.getLocation() |
      path = this.getFile().getAbsolutePath() and
      sl = loc.getStartLine() and
      sc = loc.getStartColumn() and
      el = sl and
      ec = sc
    )
  }
}

newtype TAlertPosition =
  TFrameOptions(FrameOptions fo) or
  TIndexHtmlElement(IndexHtmlElement ihe)

class AlertPosition extends TAlertPosition {
  FrameOptions asFrameOptions() { this = TFrameOptions(result) }

  IndexHtmlElement asIndexHtmlElement() { this = TIndexHtmlElement(result) }

  string toString() {
    result = this.asFrameOptions().toString() or
    result = this.asIndexHtmlElement().toString()
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
    /* This is an IndexHtmlElement */
    this.asIndexHtmlElement().hasLocationInfo(path, sl, sc, el, ec)
  }
}

from AlertPosition alert, string message
where
  exists(FrameOptions frameOptions | frameOptions.allowsAllOriginEmbedding() |
    alert.asFrameOptions() = frameOptions and
    message =
      "Possible clickjacking vulnerability due to " + frameOptions.toString() +
        " being set to `allow`."
  )
  or
  exists(UI5::Project p | thereIsNoFrameOptionSet(p) |
    exists(HTML::HtmlFile file, IndexHtmlElement doc |
      file = p.getMainHTML() and
      doc.getFile() = file and
      alert.asIndexHtmlElement() = doc
    ) and
    message = "Possible clickjacking vulnerability due to missing frame options."
  )
select alert, message
