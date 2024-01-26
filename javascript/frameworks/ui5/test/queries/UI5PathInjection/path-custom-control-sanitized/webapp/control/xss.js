sap.ui.define([
    "sap/ui/core/Control",
    "sap/base/security/encodeXML"
], function (Control, encodeXML) {
    return Control.extend("codeql-sap-js.control.xss", {
        metadata: {
            properties: {
                text: { type: "string" }
            }
        },
        renderer: {
            apiVersion: 2,
            render: function (oRm, oControl) {
                oRm.openStart("div", oControl);
                var value = oControl.getText();
                var xssSanitized = encodeXML(String(value)) // XSS sanitizer applied.
                sap.ui.core.util.File.put("someKey", xssSanitized); // Data not sanitized for a path injection sink.
                oRm.unsafeHtml(xssSanitized); // Data sanitized for a XSS sink.
                oRm.close("div");
            }
        }
    });
})
