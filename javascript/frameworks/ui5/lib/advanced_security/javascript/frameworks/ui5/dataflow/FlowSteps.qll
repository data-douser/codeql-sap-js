import javascript
import advanced_security.javascript.frameworks.ui5.UI5

/**
 * Step from a part of internal model to a relevant control property.
 * e.g.
 * - There is a JSON model with content `{ x: null }`,
 * - There is a user-defined custom control `C` with property `{ y: { type: "string" } }`, and
 * - The two are associated in a control declaration in a view with a binding path `<C y={/x} />`.
 *
 * Then, there is a step from the content `{ x: null }` to `{ y: { type: "string" } }`.
 */
class InternalModelContentToCustomMetadataPropertyStep extends DataFlow::SharedFlowStep {
  override predicate step(DataFlow::Node start, DataFlow::Node end) {
    exists(UI5BindingPath bindingPath |
      bindingPath.getNode() = start and
      end =
        bindingPath
            .getControlDeclaration()
            .getDefinition()
            .getMetadata()
            .getProperty(bindingPath.getPropertyName())
    )
  }
}

/**
 * This is a step in the opposite direction of the `InternalModelContentToCustomMetadataPropertyStep` above.
 * In order to ensure that this indeed holds, we check if the internal model is set to a two-way binding mode.
 */
class CustomMetadataPropertyStepToInternalModelContent extends DataFlow::SharedFlowStep {
  override predicate step(DataFlow::Node start, DataFlow::Node end) {
    exists(UI5BindingPath bindingPath, UI5InternalModel internalModel |
      start =
        bindingPath
            .getControlDeclaration()
            .getDefinition()
            .getMetadata()
            .getProperty(bindingPath.getPropertyName()) and
      bindingPath.getNode() = end and
      /* Get the content of the internal model and check if it's two-way bound. */
      internalModel.(JsonModel).getAProperty() = end and // TODO: Generalize to UI5InternalModel
      internalModel.(JsonModel).isTwoWayBinding() // TODO: Generalize to UI5InternalModel
    )
  }
}

/** External model to a relevant control property */
class ExternalModelToCustomMetadataPropertyStep extends DataFlow::SharedFlowStep {
  override predicate step(DataFlow::Node start, DataFlow::Node end) {
    exists(UI5BindingPath bindingPath |
      bindingPath.getModel() = start and
      end =
        bindingPath
            .getControlDeclaration()
            .getDefinition()
            .getMetadata()
            .getProperty(bindingPath.getPropertyName())
    )
  }
}

/** Control metadata property being the intermediate flow node */
class CustomMetadataPropertyReadStep extends DataFlow::SharedFlowStep {
  override predicate step(DataFlow::Node start, DataFlow::Node end) {
    exists(PropertyMetadata property |
      /* Writing site -> Control property */
      start = property.getAWrite().getArgument(1) and
      end = property
      or
      /* Control property -> Reading site */
      start = property and
      end = property.getARead()
    )
  }
}

/**
 * Step from the second argument of `setProperty` method call on a local model or a reference to that model, that is, the receiver.
 *
 * e.g. Given these methods in a same controller,
 *
 * ```javascript
 * onInit: {
 *   var oModel = new JSONModel({ x: null });  // A local model
 *   this.getView().setModel(oModel);
 * }
 *
 * someHandler: {
 *   this.getView().getModel().setProperty("x", someValue);
 * }
 * ```
 *
 * Create an edge from `someValue` to `this.getView().getModel()`.
 */
class LocalModelSetPropertyStep extends DataFlow::SharedFlowStep {
  override predicate step(DataFlow::Node start, DataFlow::Node end) {
    /* 1. The receiver is a reference to the local model */
    exists(
      MethodCallNode setPropertyCall, CustomController controller,
      InternalModelManifest internalModelManifest, ModelReference modelRef
    |
      start = setPropertyCall.getArgument(1) and
      setPropertyCall.getMethodName() = "setProperty" and
      setPropertyCall.getReceiver().getALocalSource() = modelRef and
      /* We're applying TC + since the `modelRef` can be inside a callback argument. */
      modelRef.asExpr().getEnclosingFunction+() = controller.getAHandler().getFunction() and
      controller.getAModelReference() = modelRef and
      /* `modelRef.getModelName()` can be found in manifest.js */
      internalModelManifest.getName() = modelRef.getModelName() and
      modelRef = end
    )
    or
    /* 2. The receiver is a the local model value itself */
    exists(
      MethodCallNode setPropertyCall, CustomController controller, UI5InternalModel internalModel
    |
      start = setPropertyCall.getArgument(1) and
      setPropertyCall.getMethodName() = "setProperty" and
      setPropertyCall.getReceiver().getALocalSource() = internalModel and
      /* We're applying TC + since the `internalModel` can be inside a callback argument. */
      internalModel.asExpr().getEnclosingFunction+() = controller.getAHandler().getFunction() and
      internalModel = end
    )
  }
}

/**
 * Step from the model 
 */
/* TODO: Remove the check to the presence of `setPropertyCall`. */
class LocalModelGetPropertyStep extends DataFlow::SharedFlowStep {
  override predicate step(DataFlow::Node start, DataFlow::Node end) {
    exists(
      MethodCallNode getPropertyCall, ModelReference modelRefTo, ModelReference modelRefFrom,
      MethodCallNode setPropertyCall
    |
      setPropertyCall.getMethodName() = "setProperty" and
      setPropertyCall.getReceiver().getALocalSource() = modelRefFrom and
      start = modelRefFrom and
      getPropertyCall.getMethodName() = "getProperty" and
      getPropertyCall.getReceiver().getALocalSource() = modelRefTo and
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
  override predicate step(DataFlow::Node start, DataFlow::Node end) {
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
      control.getMetadata().getProperty(binding.getBindingTarget().asXmlAttribute().getName()) = end
    )
  }
}

class SetModelToGetModelStep extends DataFlow::SharedFlowStep {
  override predicate step(DataFlow::Node start, DataFlow::Node end) {
    exists(UI5Model modelDefinition, ModelReference modelReference |
      modelReference.getResolvedModel() = modelDefinition and
      start = modelDefinition and
      end = modelReference
    )
  }
}

class GetModelToGetPropertyStep extends DataFlow::SharedFlowStep {
  override predicate step(DataFlow::Node start, DataFlow::Node end) {
    exists(ModelReference modelReference, MethodCallNode readingMethodCall |
      readingMethodCall = modelReference.getARead() and
      start = modelReference and
      end = readingMethodCall
    )
  }
}
