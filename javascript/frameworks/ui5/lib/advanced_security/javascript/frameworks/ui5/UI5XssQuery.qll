import advanced_security.javascript.frameworks.ui5.UI5DataFlow
import semmle.javascript.security.dataflow.DomBasedXssQuery as DomBasedXss

class Configuration extends DomBasedXss::Configuration {
  /** WARNING: VALID FOR THIS BRANCH (`jeongsoolee09/remote-model-1`) ONLY */
  override predicate isSource(DataFlow::Node start) { start instanceof UI5ExternalModel }

  override predicate isAdditionalFlowStep(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    /* 1. Already an additional flow step defined in `DomBasedXssQuery::Configuration` */
    super.isAdditionalFlowStep(start, end, inLabel, outLabel)
    or
    /* 2. Already an additional flow step defined in `UI5DataFlow` */
    /*
     * TODO: de-deduplicate one of `isAdditionalFlowStep` by integrating
     * UI5DataFlow's one to this
     */

    UI5DataFlow::isAdditionalFlowStep(start, end, inLabel, outLabel)
    or
    /* 3. External model to a relevant control property */
    exists(
      CustomController controller, ControllerHandler handler, PropertyMetadata controlMetadata,
      RouteManifest routeManifest, PropRead parameterAccess, UI5BindingPath bindingPath
    |
      /* 1. Validate that the controller has a handler attached to a route */
      start = controller.getModel().(UI5ExternalModel) and
      handler = controller.getAHandler() and
      handler.isAttachedToRoute(routeManifest.getName()) and
      routeManifest.matchesPathString(parameterAccess.getPropertyName()) and
      parameterAccess
          .flowsToExpr(controller
                .getAViewReference()
                .getABindElementCall()
                .getArgument(0)
                .asExpr()
                .(ObjectExpr)
                .getPropertyByName("path")
                .getInit()
                // TODO: `BinaryExpr.getAnOperand` is too narrow
                .(BinaryExpr)
                .getAnOperand()) and
      /* 2. Get the control associated with it */
      bindingPath.getModel() = start and
      controlMetadata =
        bindingPath
            .getControlDeclaration()
            .getDefinition()
            .getMetadata()
            .getProperty(bindingPath.getPropertyName()) and
      /* Grand finale. We're done! */
      end = controlMetadata
    )
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
    // node instanceof UI5ModelHtmlISink or
    node instanceof UI5ExtHtmlISink
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
