import javascript
import advanced_security.javascript.frameworks.ui5.dataflow.DataFlow as UI5DataFlow
import advanced_security.javascript.frameworks.ui5.UI5View
import semmle.javascript.security.dataflow.DomBasedXssQuery as DomBasedXss
import semmle.javascript.security.dataflow.ClientSideUrlRedirectCustomizations::ClientSideUrlRedirect as UrlRedirect

class Configuration extends DomBasedXss::Configuration {
  /** WARNING: VALID FOR THIS BRANCH (`jeongsoolee09/remote-model-1`) ONLY */
  override predicate isSource(DataFlow::Node start) {
    super.isSource(start)
    or
    start instanceof RemoteFlowSource
  }

  override predicate isAdditionalFlowStep(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    /* 1. Already an additional flow step defined in `DomBasedXssQuery::Configuration` */
    super.isAdditionalFlowStep(start, end, inLabel, outLabel)
    or
    /* 2. An additional flow step defined in `UI5DataFlow` */
    UI5DataFlow::isAdditionalFlowStep(start, end)
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

  override predicate isSink(DataFlow::Node node) {
    node instanceof UI5ExtHtmlISink or
    node instanceof UrlRedirect::LocationSink or
    node instanceof UI5ModelHtmlISink
  }
}

/**
 * An HTML injection sink associated with a `UI5BoundNode`, typically for library controls acting as sinks.
 */
private class UI5ModelHtmlISink = UI5ExternalModel;

/**
 * An HTML injection sink typically for custom controls whose RenderManager calls acting as sinks.
 */
private class UI5ExtHtmlISink extends DomBasedXss::Sink {
  UI5ExtHtmlISink() { this = ModelOutput::getASinkNode("ui5-html-injection").asSink() }
}

predicate isUI5Sink(UI5PathGraph::UI5PathNode sink) {
  sink.asDataFlowNode() instanceof UI5ModelHtmlISink or
  sink.asDataFlowNode() instanceof UI5ExtHtmlISink
}
