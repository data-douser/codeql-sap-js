sap.ui.define(
  ["sap/ui/core/mvc/Controller", "sap/ui/model/json/JSONModel"],
  function (Controller) {
    "use strict";
    return Controller.extend("sample.controller.app", {
      sample: function () {
        var inputRef = this.getView().byId("sap-input");
        var htmlRef = this.byId("sap-html");
        var control1Ref = this.getView().byId("customControl1");
        var control2Ref = this.byId("customControl2");

        /* ========== Getter test ========== */
        /*
         * 1-1. Getting from existing properties of a custom control.
         * These should be captured by ControlReference.getARead().
         */
        var _ = control1Ref.getProp1(); // Should be captured
        var _ = control1Ref.getProperty("prop1"); // Should be captured

        var _ = control2Ref.getProp2(); // Should be captured
        var _ = control2Ref.getProperty("prop2"); // Should be captured

        /*
         * 1-2. Getting from (existing) properties of a library control.
         * These should be captured by ControlReference.getARead().
         */
        var _ = inputRef.getValue(); // Should be captured
        var _ = inputRef.getProperty("value"); // Should be captured

        var _ = htmlRef.getContent(); // Should be captured
        var _ = htmlRef.getProperty("content"); // Should be captured

        /*
         * 1-3. Getting from non-existent properties of a custom control.
         * These should NOT be captured by ControlReference.getARead().
         */
        var _ = control1Ref.getNonExistent1(); // Should NOT be captured
        var _ = control1Ref.getProperty("NonExistent1"); // Should NOT be captured

        var _ = control2Ref.getNonExistent2(); // Should NOT be captured 
        var _ = control2Ref.getProperty("NonExistent2"); // Should NOT be captured

        /* ========== Setter test ========== */
        /*
         * 1-1. Setting to existing properties of a custom control.
         * These should be captured by ControlReference.getAWrite().
         */
        var _ = control1Ref.setProp1("newValue"); // Should be captured
        var _ = control1Ref.setProperty("prop1", "newValue"); // Should be captured

        var _ = control2Ref.setProp2("newValue"); // Should be captured
        var _ = control2Ref.setProperty("prop2", "newValue"); // Should be captured

        /*
         * 1-2. Setting to (existing) properties of a library control.
         * These should be captured by ControlReference.getAWrite().
         */
        var _ = inputRef.setValue("newValue"); // Should be captured
        var _ = inputRef.setProperty("value", "newValue"); // Should be captured

        var _ = htmlRef.setContent("newValue"); // Should be captured
        var _ = htmlRef.setProperty("content", "newValue"); // Should be captured

        /*
         * 1-3. Setting to non-existent properties of a custom control.
         * These should NOT be captured by ControlReference.getAWrite().
         */
        var _ = control1Ref.setNonExistent1("newValue"); // Should NOT be captured 
        var _ = control1Ref.setProperty("NonExistent1", "newValue"); // Should NOT be captured 

        var _ = control2Ref.setNonExistent2("newValue"); // Should NOT be captured 
        var _ = control2Ref.setProperty("NonExistent2", "newValue"); // Should NOT be captured 
      },
    });
  }
);
