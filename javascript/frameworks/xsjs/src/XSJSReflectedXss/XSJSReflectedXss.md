# Reflected Cross-site Scripting

Including a text, received from a client browser typically through an XSJS request parameter, to be rendered as HTML in a request body may execute arbitrary JavaScript code on the client.

## Recommendation

The XSJS application should always validate or sanitize the submitted string from a client before including it into a response body to be rendered in a client browser.

### Validate the input string

Validate the submitted input by looking for a sensitive HTML tag such as `<script ...>...</script>`. The pattern may be encoded to a regular expression and matched against the input; If there is a match, then the XSJS application may decide to abort the process and instead return an HTTP code stating that the application rejected the request (e.g. `$.net.FORBIDDEN`). XSJS does not provide a function to reliably perform the above, therefore using a third-party library is recommended.

### Sanitize the input string

#### Server-side sanitization

The XSJS application may instead allow any user input, but sanitize it before it integrates it into the response body. This is achieved by escaping special characters that are treated as part of the HTML syntax, such as `"`, `&`, `'`, `<`, and `>`. Since XSJS does not provide a function to escape these, using a third-party library is recommended.

#### Client-side sanitization

Alternatively, if SAP UI5 is used on the frontend, there are client-side escaping mechanisms such as `sap.base.security.encodeXML` and `sap.base.security.encodeHTML`. If `sap.ui.core.HTML` is used in the frontend view, consider setting its `sanitizeContent` property explicitly to `true`, since its default value is `false`.

## Example

The following XSJS application sets the response body directly to a string received from a user without any validation or sanitization. The header's content type is set as an HTML document, which allows for any embedded JavaScript to be run in the request body. Note that even if `clientData` was not enclosed in a `div`, the vulnerability would still exist.

``` javascript
let clientData = requestParameters.get("someParameter");
$.response.contentType = "text/html";
$.response.setBody("<div>" + clientData + "</div>");
$.response.status = $.net.http.OK;
```

## References

* SAP: [Server-Side JavaScript Security Considerations](https://help.sap.com/docs/SAP_HANA_PLATFORM/d89d4595fae647eabc14002c0340a999/b5e65421b48c48fa87312a6023f4c414.html).
* SAP: [Server-Side JavaScript: Cross-Site Scripting
](https://help.sap.com/docs/SAP_HANA_PLATFORM/d89d4595fae647eabc14002c0340a999/0e1c9fff826a4583be715386578fffc7.html).
* OWASP: [Types of Cross-site Scripting](https://owasp.org/www-community/Types_of_Cross-Site_Scripting).
* OWASP: [Cross Site Scripting Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html).
* Common Weakness Enumeration: [CWE-79](https://cwe.mitre.org/data/definitions/79.html).
* Common Weakness Enumeration: [CWE-116](https://cwe.mitre.org/data/definitions/116.html).

