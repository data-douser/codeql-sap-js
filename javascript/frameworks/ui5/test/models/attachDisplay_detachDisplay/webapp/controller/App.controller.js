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
          .attachDisplay(function (event) {
            var bundle = this.getOwnerComponent()
              .getModel("i18n")
              .getResourceBundle();
            this.getView()
              .byId("someControl")
              .setSomeProperty(
                bundle.getText(
                  "some.section",
                  event.getParameter("someProperty").someProperty
                )
              );
          }, this);
      },
      testDetachDisplay: function () {
        this.getOwnerComponent()
          .getRouter()
          .getTarget("someRoutingTarget")
          .attachDisplay(function (event) {
            var bundle = this.getOwnerComponent()
              .getModel("i18n")
              .getResourceBundle();
            this.getView()
              .byId("someControl")
              .setSomeProperty(
                bundle.getText(
                  "some.section",
                  event.getParameter("someProperty").someProperty
                )
              );
          }, this);
      },
    });
  }
);
