/**
 * @name Client-side cross-site scripting
 * @description Writing user input directly to a UI5 View allows for
 *              a cross-site scripting vulnerability.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 6.1
 * @precision high
 * @id js/ui5-xss
 * @tags security
 *       external/cwe/cwe-079
 *       external/cwe/cwe-116
 */

import javascript
import models.UI5DataFlowShared
import models.UI5DataFlowShared::UI5PathGraph
import semmle.javascript.security.dataflow.DomBasedXssQuery as DomBasedXss

class UI5XssConfiguration extends DomBasedXss::Configuration {
  override predicate isAdditionalFlowStep(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    super.isAdditionalFlowStep(start, end, inLabel, outLabel)
    or
    UI5DataFlow::isAdditionalFlowStep(start, end, inLabel, outLabel)
  }

  override predicate isSanitizer(DataFlow::Node node) {
    super.isSanitizer(node)
    or
    // value read from a non-string property
    exists(string prop_name |
      node = any(Metadata m | not m.isUnrestrictedStringType(prop_name)).getProperty(prop_name)
    )
    or
    // UI5 sanitizers
    exists(SapAmdModuleDefinition d, DataFlow::ParameterNode par |
      node = par.getACall() and
      par.getParameter() =
        d.getDependencyParameter("sap/base/security/" +
            ["encodeCSS", "encodeJS", "encodeURL", "encodeURLParameters", "encodeXML"])
    )
    or
    // UI5 jQuery sanitizers
    node.(DataFlow::CallNode).getReceiver().asExpr().(PropAccess).getQualifiedName() = "jQuery.sap" and
    node.(DataFlow::CallNode).getCalleeName() =
      ["encodeCSS", "encodeJS", "encodeURL", "encodeURLParameters", "encodeXML", "encodeHTML"]
  }
}

/**
 * An remote source associated with a `UI5BoundNode`
 */
class UI5ModelSource extends UI5DataFlow::UI5ModelSource, DomBasedXss::Source { }

/**
 * An html injection sink associated with a `UI5BoundNode`
 */
class UI5ModelHtmlISink extends UI5DataFlow::UI5ModelHtmlISink, DomBasedXss::Sink { }

from
  UI5XssConfiguration cfg, UI5PathGraph::UI5PathNode source, UI5PathGraph::UI5PathNode sink,
  UI5PathGraph::UI5PathNode primarySource, UI5PathGraph::UI5PathNode primarySink
where
  cfg.hasFlowPath(source.asDataFlowPathNode(), sink.asDataFlowPathNode()) and
  primarySource = source.getAPrimarySource() and
  primarySink = sink.getAPrimaryHtmlISink()
select primarySink, primarySource, primarySink, "XSS vulnerability due to $@.", primarySource,
  "user-provided value"
