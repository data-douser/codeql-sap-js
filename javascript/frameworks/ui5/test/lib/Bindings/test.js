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

        // Early dynamic property binding
        const model = "model";
        var oInputWithEarlyDynamicPropertyBinding = new sap.m.Input({
            value: "{" + model + "</root/name}"
        });

        var oInputWithLateBinding = this.byId("foo");
        // Late context binding
        oInput.bindElement("/root");
        // Late property binding
        oInput.bindProperty("value", "name");

       // Early composite binding
       var oInputWithEarlyContextBinding = new sap.m.Input({
           value: {
               parts: [
                   { path: "/foo", type: new sap.ui.model.type.String() },
                   { path: "/bar" },
                   { path: "baz>/quux", type: new sap.ui.model.type.Float() }
               ]
           }
        });

        // Late composite binding
        var oInputWithLateContextBinding = this.byId("foo");
        oInputWithLateContextBinding.bindValue({
            parts: [
                { path: "/foo", type: new sap.ui.model.type.String() },
                { path: "/bar" },
                { path: "baz>/quux", type: new sap.ui.model.type.Float() }
            ]
        });

        // Early property metadata binding
        var oLabel = new sap.m.Label({
            text: "{/#foo/bar/@sap:label}"
        });
       }
    });
});