/**
 * `DataFlow::Node`s common to all security queries.
 */

import javascript
import advanced_security.javascript.frameworks.cap.CDS

/**
 * Methods that parse source strings into a CQL expression.
 */
class ParseSink extends DataFlow::Node {
    ParseSink() {
      this =
        any(CdsFacade cds)
            .getMember("parse")
            .getMember(["expr", "ref", "xpr"])
            .getACall()
            .getAnArgument()
    }
  }