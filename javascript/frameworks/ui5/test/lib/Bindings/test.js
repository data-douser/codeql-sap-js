sap.ui.define([
    "sap/ui/core/mvc/Controller"
], function(Controller) {
    "use strict";

    return Controller.extend("foo", {
       onInit: function() {
        // Early property binding
        var oInputWithEarlyPropertyBinding = new sap.m.Input({
            value: "{/root/name}"
        });

        var oInputWithLateBinding = this.byId("foo");
        // Late context binding
        oInput.bindElement("/root");
        // Late property binding
        oInput.bindProperty("value", "name");
       }
    });
});