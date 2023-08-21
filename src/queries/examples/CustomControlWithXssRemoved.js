sap.ui.define(["sap/ui/core/Control", "sap/base/security/encodeXML"], function (Control, encodeXML) {
    return Control.extend("vulnerable.control.xss", {
        metadata: { properties: { text: { type: "int" } } }, // 1. constrain the type
        renderer: {
            apiVersion: 2,
            render: function (oRm, oControl) {
                oRm.openStart("div", oControl);
                oRm.unsafeHtml(encodeXML(oControl.getText()); // 2. use security functions
                oRm.close("div");
            }
        }
    });
})
