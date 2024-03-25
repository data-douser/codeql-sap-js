sap.ui.define(
  ["sap/ui/core/mvc/Controller", "sap/ui/model/json/JSONModel"],
  function (Controller) {
    "use strict";
    return Controller.extend("sample.controller.app", {
      method1: function () {},
      method2: function (event) {},
      testAttachDisplay: function () {
        this.getOwnerComponent()
          .getRouter()
          .getTarget("someRoutingTarget")
          .attachDisplay(function (event) {}, this);
      },
      testDetachDisplay: function () {
        this.getOwnerComponent()
          .getRouter()
          .getTarget("someRoutingTarget")
          .detachDisplay(function (event) {}, this);
      },
    });
  },
);
