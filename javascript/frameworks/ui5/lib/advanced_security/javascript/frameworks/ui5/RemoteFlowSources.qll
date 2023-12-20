import javascript
import advanced_security.javascript.frameworks.ui5.UI5

abstract class UI5ExternalModel extends UI5Model, RemoteFlowSource {
  abstract string getName();
}

/** Model which gains content from an SAP OData service. */
class ODataServiceModel extends UI5ExternalModel {
  string modelName;

  override string getSourceType() { result = "ODataServiceModel" }

  ODataServiceModel() {
    /*
     * e.g. this.getView().setModel(this.getOwnerComponent().getModel("booking_nobatch"))
     */

    exists(MethodCallNode setModelCall, CustomController controller |
      /*
       * 1. This flows from a DF node corresponding to the parent component's model to the `this.setModel` call
       * i.e. Aims to capture something like `this.getOwnerComponent().getModel("someModelName")` as in
       * `this.getView().setModel(this.getOwnerComponent().getModel("someModelName"))`
       */

      modelName = this.getArgument(0).getALocalSource().asExpr().(StringLiteral).getValue() and
      this.getCalleeName() = "getModel" and
      controller.getOwnerComponentRef().flowsTo(this.(MethodCallNode).getReceiver()) and
      this.flowsTo(setModelCall.getArgument(0)) and
      setModelCall.getMethodName() = "setModel" and
      setModelCall.getReceiver() = controller.getAViewReference() and
      /* 2. The component's manifest.json declares the DataSource as being of OData type */
      controller.getOwnerComponent().getExternalModelDef(modelName).getDataSource() instanceof
        ODataDataSourceManifest
    )
    or
    /*
     * A constructor call to sap.ui.model.odata.v2.ODataModel.
     */

    this instanceof NewNode and
    (
      exists(RequiredObject oDataModel |
        oDataModel.flowsTo(this.getCalleeNode()) and
        oDataModel.getDependencyType() = "sap/ui/model/odata/v2/ODataModel"
      )
      or
      this.getCalleeName() = "ODataModel"
    ) and
    modelName = "<no name>"
  }

  override string getName() { result = modelName }
}