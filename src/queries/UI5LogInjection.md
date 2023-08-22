# Log Injection

A UI5 application may leak sensitive information through its logging facility if it directly or indirectly passes the data around which ends up in a logging function provided by UI5. It is also possible that a malicious actor submits a crafted user input which might lead to forging log entries.

## Recommendation

The author of the application should be aware of what sensitive information there is, prepare appropriate sanitizers such as anonymizing functions, and keep check of how and whether the logged information is being sanitized.

Also, avoid directly logging untrusted input from a remote source. Only log parts of the input, not the whole content, so that it becomes indistinguishable from system-generated log messages.

## Examples

This UI5 application directly outputs what the user submitted via the `sap.m.Input` control.

``` xml
<sap.ui.core.mvc.View controllerName="vulnerable.controller.app">
  <SearchField id="searchTodoItemsInput"
  width="20rem" search=".onSearchCompleted" /> <!-- Source -->
</sap.ui.core.mvc.View>
```

``` javascript
sap.ui.define(
  [
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/json/JSONModel",
    "sap/base/Log/info",
  ],
  function (Controller, JSONModel, info) {
    return Controller.extend("vulnerable.controller.app", {
      onSearchCompleted: function () {
        var oView = this.getView();
        var oSearchField = oView.byId("searchTodoItemsInput");
        var searchValue = oSearchField.getValue();
        info(searchValue); // Sink
      },
    });
  },
);

## References

- OWASP: [Log Injection](https://www.owasp.org/index.php/Log_Injection)
- SAP: [namespace `sap/base/Log`](https://sapui5.hana.ondemand.com/sdk/#api/module:sap/base/Log)
