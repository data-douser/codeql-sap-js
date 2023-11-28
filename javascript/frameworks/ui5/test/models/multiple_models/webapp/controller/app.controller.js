sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/json/JSONModel",
    "sap/ui/model/odata/v2/ODataModel",
    "sap/m/Input"
], function (Controller, JSONModel, ODataModel, Input) {
    "use strict"
    return Controller.extend("codeql-sap-js.controller.app", {
        onInit: function () {
            /* 1. Setting an ODataModel as a default model and two JSON models as helpers on THE ENTIRE VIEW */
            var oModelDefault1 = new ODataModel();
            var oModel11 = new JSONModel();
            var oModel12 = new JSONModel();
            this.getView().setModel(oModelDefault1);
            this.getView().setModel(oModel11, "model1");
            this.getView().setModel(oModel12, "model2");
            
            /* 2. Setting an ODataModel as a default model and two JSON models as helpers on A NEW CONTROL */
            var oControl = new Input();
            var oModelDefault2 = new ODataModel();
            var oModel21 = new JSONModel();
            var oModel22 = new JSONModel();
            oControl.setModel(oModelDefault);
            oControl.setModel(oModel21, "model1");
            oControl.setModel(oModel22, "model2");

            /* 3. Setting an ODataModel as a default model and two JSON models as helpers on A CONTROL REFERENCE */
            var oControl = this.getView().byId("unit-test-target");
            var oModelDefault2 = new ODataModel();
            var oModel31 = new JSONModel();
            var oModel32 = new JSONModel();
            oControl.setModel(oModelDefault);
            oControl.setModel(oModel31, "model1");
            oControl.setModel(oModel32, "model2");
        }
    });
})