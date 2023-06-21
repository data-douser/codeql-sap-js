sap.ui.define([
    "sap/ui/core/Control"
], function (Control) {
    return Control.extend("sap.ui5.xss.control.xss", {
        metadata: {
            properties: {
                text: { type: "string" }
            }
        },
        renderer: function (oRm, oControl) {
            oRm.write("<div");
            oRm.writeControlData(oControl);
            oRm.write(">");
            oRm.write(oControl.getText()); // XSS sink RenderManager.write
            oRm.write("</div>")
        }
    });
})
