sap.ui.define(["sap/ui/core/Control"], function (Control) {
  return Control.extend("sample.control.control1", {
    metadata: {
      properties: {
        prop1: { type: "string" },
      },
    },
  });
});
