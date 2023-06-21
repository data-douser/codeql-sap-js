sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/json/JSONModel"
], function (Controller, JSONModel) {
    "use strict"
    return Controller.extend("sap.ui5.xss.controller.app", {
        onInit: function () {
            var oData = {
                input: null
            };
            var oModel = new JSONModel(oData);
            this.getView().setModel(oModel);
        }
    });
})