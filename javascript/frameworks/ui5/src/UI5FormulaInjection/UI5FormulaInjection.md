# Formula injection

UI5 applications that save local data, fetched from an uncontrolled remote source, into a CSV file format using generic APIs such as [`sap.ui.core.util.File.save`](https://sapui5.hana.ondemand.com/sdk/#/api/sap.ui.core.util.File%23methods/sap.ui.core.util.File.save) are vulnerable to formula injection, or CSV injection.

## Recommendation

### Escape the leading special characters

CSV cells containing leading special characters such as an equal sign (`=`) may be interpreted as spreadsheet formulas. To prevent them from being interpreted these prefixes should be escaped by surrounding the prefixes with single quotes in order to keep them as literal strings.

### Use a dedicated API function

Manual construction of a CSV file using string concatenation is prone to mistakes that can lead to security issues. Instead, a dedicated library function should be used. For example, if the target being exported is a [`sap.m.Table`](https://sapui5.hana.ondemand.com/sdk/#/api/sap.m.Table) and the resulting file is to intended to be opened using a spreadsheet program anyways, then using one of the API functions provided by [`sap.ui.export.Spreadsheet`](https://sapui5.hana.ondemand.com/#/entity/sap.ui.export.Spreadsheet) is the preferred method of achieving the same exporting functionality.

## Example

The following controller is exporting a CSV file obtained from an event parameter by surrounding it in a pair of semicolons (`;`) as CSV separators.

``` javascript
sap.ui.define([
    "sap/ui/core/Controller",
    "sap/ui/core/util/File"
  ], function(Controller, File) {
    return Controller.extend("vulnerable.controller.app", {
      onSomeEvent: function(oEvent) {
         let response = oEvent.getProperty("someProperty").someField;
         let csvRow = ";" + response + ";";
         File.save(csvRow, "someFile", "csv", "text/csv", "utf-8");
      }
    });
  });
```

## References

- OWASP: [CSV Injection](https://owasp.org/www-community/attacks/CSV_Injection).
- Common Weakness Enumeration: [CWE-1236](https://cwe.mitre.org/data/definitions/1236.html).
- SAP UI5 API Reference: [`sap.ui.export.Spreadsheet`](https://sapui5.hana.ondemand.com/#/entity/sap.ui.export.Spreadsheet).
- SAP UI5 API Reference: [`sap.ui.core.util.File.save`](https://sapui5.hana.ondemand.com/sdk/#/api/sap.ui.core.util.File%23methods/sap.ui.core.util.File.save).
