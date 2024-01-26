sap.ui.define([
    "sap/ui/core/Control"
], function (Control) {
    return Control.extend("codeql-sap-js.control.xss", {
        metadata: {
            properties: {
                text: { type: "int" }
            }
        },
        renderer: {
            apiVersion: 2,
            render: function (oRm, oControl) {
                sap.ui.core.util.File.put("someKey", oControl.getText()) // Path injection sink, data is not sanitized.
            }
        }
    });
})
