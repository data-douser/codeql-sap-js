sap.ui.define(["sap/ui/core/Control"], function (Control) {
    return Control.extend("vulnerable.control.xss", {
        metadata: { properties: { text: { type: "string" } } },
        renderer: {
            apiVersion: 2,
            render: function (oRm, oControl) {
                oRm.openStart("div", oControl);
                oRm.unsafeHtml(oControl.getText()); // sink
                oRm.close("div");
            }
        }
    });
})
