import javascript
import advanced_security.javascript.frameworks.ui5.UI5

/** External model to a relevant control property */
class ExternalModelToCustomMetadataPropertyStep extends DataFlow::SharedFlowStep {
  override predicate step(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    exists(UI5BindingPath bindingPath |
      bindingPath.getModel() = start and
      end =
        bindingPath
            .getControlDeclaration()
            .getDefinition()
            .getMetadata()
            .getProperty(bindingPath.getPropertyName()) and
      // (
      //   inLabel = "taint" and outLabel = "taint"
      //   or
      //   inLabel = bindingPath.getPath() and outLabel = bindingPath.getPath()
      // )
      if any(UI5BindingPath path/* | path.getModel() = start*/ ).getPath() = inLabel
      then inLabel = bindingPath.getPath() and inLabel = outLabel
      else inLabel = outLabel
    )
  }
}

/*
 * <A a="path1"> a.control.js: {path1: {type:string}}
 * <B b="path1"> b.control.js: {path1: {type:string}}
 */

/** Control metadata property being the intermediate flow node */
class CustomMetadataPropertyReadStep extends DataFlow::SharedFlowStep {
  override predicate step(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    exists(PropertyMetadata property |
      /* Writing site -> Control property */
      start = property.getAWrite().getArgument(1) and
      end = property
      or
      /* Control property -> Reading site */
      start = property and
      end = property.getARead()
    ) and
    inLabel = outLabel
  }
}

class LocalModelSetPropertyStep extends DataFlow::SharedFlowStep {
  override predicate step(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    exists(
      MethodCallNode setPropertyCall, ModelReference modelRef, CustomController controller,
      InternalModelManifest internalModelManifest
    |
      setPropertyCall.getMethodName() = "setProperty" and
      setPropertyCall.getReceiver().getALocalSource() = modelRef and
      /* We're applying TC + since the `modelRef` can be inside a callback argument. */
      modelRef.asExpr().getEnclosingFunction+() = controller.getAHandler().getFunction() and
      controller.getAModelReference() = modelRef and
      /* `modelRef.getModelName()` can be found in manifest.js */
      internalModelManifest.getName() = modelRef.getModelName() and
      setPropertyCall.getArgument(1) = start and
      modelRef = end and
      /* Any inLabel */
      inLabel = inLabel and
      outLabel =
        modelRef.getModelName() + ">" +
          setPropertyCall.getArgument(0).getALocalSource().asExpr().getStringValue()
    )
  }
}

class LocalModelGetPropertyStep extends DataFlow::SharedFlowStep {
  override predicate step(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    exists(
      MethodCallNode getPropertyCall, ModelReference modelRefTo, ModelReference modelRefFrom,
      MethodCallNode setPropertyCall
    |
      setPropertyCall.getMethodName() = "setProperty" and
      setPropertyCall.getReceiver().getALocalSource() = modelRefFrom and
      start = modelRefFrom and
      getPropertyCall.getMethodName() = "getProperty" and
      getPropertyCall.getReceiver().getALocalSource() = modelRefTo and
      inLabel =
        modelRefTo.getModelName() + ">" +
          getPropertyCall.getArgument(0).getALocalSource().asExpr().getStringValue() and
      outLabel = "taint" and
      end = getPropertyCall and
      /*
       * Ensure that getPropertyCall and setPropertyCall are both reading/writing from/to
       * the (1) same property of the (2) same model.
       */

      getPropertyCall.getArgument(0).getALocalSource().asExpr().getStringValue() =
        setPropertyCall.getArgument(0).getALocalSource().asExpr().getStringValue() and
      modelRefFrom.getModelName() = modelRefTo.getModelName()
    )
  }
}

class LocalModelControlMetadataStep extends DataFlow::SharedFlowStep {
  override predicate step(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    exists(
      ModelReference modelRef, BindingPath bindingPath, Binding binding, CustomControl control,
      MethodCallNode setPropertyCall
    |
      setPropertyCall.getMethodName() = "setProperty" and
      setPropertyCall.getReceiver().getALocalSource() = modelRef and
      bindingPath = binding.getBindingPath() and
      bindingPath.asString() =
        modelRef.getModelName() + ">" +
          setPropertyCall.getArgument(0).getALocalSource().asExpr().getStringValue() and
      start = modelRef and
      // modelRef.getModelName() = binding.getBindingPath().getModelName() and
      binding.getBindingPath().asString() = inLabel and
      control.getMetadata().getProperty(binding.getBindingTarget().asXmlAttribute().getName()) = end and
      outLabel = "taint"
    )
  }
}

class SetModelToGetModelStep extends DataFlow::SharedFlowStep {
  override predicate step(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    exists(UI5Model modelDefinition, ModelReference modelReference |
      modelReference.getResolvedModel() = modelDefinition and
      start = modelDefinition and
      end = modelReference and
      inLabel = inLabel and // any inLabel
      outLabel = outLabel // any outLabel
    )
  }
}

class GetModelToGetPropertyStep extends DataFlow::SharedFlowStep {
  override predicate step(
    DataFlow::Node start, DataFlow::Node end, DataFlow::FlowLabel inLabel,
    DataFlow::FlowLabel outLabel
  ) {
    exists(ModelReference modelReference, MethodCallNode readingMethodCall |
      readingMethodCall = modelReference.getARead() and
      start = modelReference and
      end = readingMethodCall and
      inLabel = inLabel and // any inLabel
      outLabel = "taint"
    )
  }
}