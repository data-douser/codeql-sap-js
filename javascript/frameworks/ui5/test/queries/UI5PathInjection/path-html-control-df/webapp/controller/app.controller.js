sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/json/JSONModel",
    "sap/ui/core/util/File"
], function (Controller, JSONModel, File) {
    "use strict";
    return Controller.extend("codeql-sap-js.controller.app", {
        onInit: function () {
            var oData = {
                input: null,
            };
            var oModel = new JSONModel(oData);
            this.getView().setModel(oModel);

            /* Data is not sanitized against formula injection. */
            File.save("some_content", oModel.getProperty('/input'), "csv", "text/csv", "utf-8");
        }
    });
}
);
