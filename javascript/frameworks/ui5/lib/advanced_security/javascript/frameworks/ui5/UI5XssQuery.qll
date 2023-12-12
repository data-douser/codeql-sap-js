import advanced_security.javascript.frameworks.ui5.UI5DataFlow
import semmle.javascript.security.dataflow.DomBasedXssQuery as DomBasedXss

class Configuration extends DomBasedXss::Configuration {
  override predicate isAdditionalFlowStep(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    super.isAdditionalFlowStep(start, end, inLabel, outLabel)
    or
    UI5DataFlow::isAdditionalFlowStep(start, end, inLabel, outLabel)
  }

  override predicate isSanitizer(DataFlow::Node node) {
    /* 1. Already a sanitizer defined in `DomBasedXssQuery::Configuration` */
    super.isSanitizer(node)
    or
    /* 2. Value read from a non-string control property */
    node = any(PropertyMetadata m | not m.isUnrestrictedStringType())
    or
    /* 3-1. Sanitizers provided by `sap.base.security` */
    exists(SapAmdModuleDefinition d, DataFlow::ParameterNode par |
      node = par.getACall() and
      par.getParameter() =
        d.getDependencyParameter("sap/base/security/" +
            ["encodeCSS", "encodeJS", "encodeURL", "encodeURLParameters", "encodeXML"])
    )
    or
    /* 3-2. Santizers provided by `jQuery.sap` */
    node.(DataFlow::CallNode).getReceiver().asExpr().(PropAccess).getQualifiedName() = "jQuery.sap" and
    node.(DataFlow::CallNode).getCalleeName() =
      ["encodeCSS", "encodeJS", "encodeURL", "encodeURLParameters", "encodeXML", "encodeHTML"]
  }
}

/**
 * An HTML injection sink associated with a `UI5BoundNode`, typically for library controls acting as sinks.
 */
private class UI5ModelHtmlISink extends UI5DataFlow::UI5ModelHtmlISink, DomBasedXss::Sink { }

/**
 * An HTML injection sink typically for custom controls whose RenderManager calls acting as sinks.
 */
private class UI5ExtHtmlISink extends DomBasedXss::Sink {
  UI5ExtHtmlISink() { this = ModelOutput::getASinkNode("ui5-html-injection").asSink() }
}

predicate isUI5Sink(UI5PathGraph::UI5PathNode sink) {
  sink.asDataFlowPathNode().getNode() instanceof UI5ModelHtmlISink or
  sink.asDataFlowPathNode().getNode() instanceof UI5ExtHtmlISink
}
