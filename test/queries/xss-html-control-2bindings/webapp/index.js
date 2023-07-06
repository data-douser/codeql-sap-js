sap.ui.define([
    "sap/ui/core/mvc/XMLView"
], function (XMLView) {
    "use strict";
    XMLView.create({
        viewName: "codeql-sap-js.view.app1"
    }).then(function (oView) {
        oView.placeAt("content1");
    });
    XMLView.create({
        viewName: "codeql-sap-js.view.app2"
    }).then(function (oView) {
        oView.placeAt("content2");
    });

}); 