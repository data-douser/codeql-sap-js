sap.ui.define([
    "sap/ui/core/Control",
    "sap/ui/core/util/File"
], function (Control, File) {
    return Control.extend("codeql-sap-js.control.xss", {
        metadata: {
            properties: {
                text: { type: "int" }
            }
        },
        renderer: {
            apiVersion: 2,
            render: function (oRm, oControl) {
                /* Data is sanitized against XSS. */
                oRm.unsafeHtml(oControl.getText());
                /* Data is not sanitized against formula injection. */
                File.save(oControl.getText(), "/some/path/", "csv", "text/csv", "utf-8");
            }
        }
    });
})
