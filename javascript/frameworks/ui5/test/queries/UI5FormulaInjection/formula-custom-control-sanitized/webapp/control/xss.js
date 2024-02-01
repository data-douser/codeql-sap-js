sap.ui.define([
    "sap/ui/core/Control",
    "sap/base/security/encodeXML",
    "sap/ui/core/util/File"
], function (Control, encodeXML, File) {
    return Control.extend("codeql-sap-js.control.xss", {
        metadata: {
            properties: {
                text: { type: "string" }
            }
        },
        renderer: {
            apiVersion: 2,
            render: function (oRm, oControl) {
                var value = oControl.getText();
                /* XSS sanitizer is applied. */
                var xssSanitized = encodeXML(String(value));
                oRm.openStart("div", oControl);
                /* Data is sanitized against XSS. */
                oRm.unsafeHtml(xssSanitized);
                oRm.close("div");
                /* Data is not sanitized against formula injection. */
                File.save(xssSanitized, "/some/path/", "csv", "text/csv", "utf-8");
            }
        }
    });
})
