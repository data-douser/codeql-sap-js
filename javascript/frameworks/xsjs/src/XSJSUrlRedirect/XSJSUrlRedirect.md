# URL Redirect

An HTTP response sent by an XSJS server whose value of the `location` header is dependent on a user input can redirect the client to an arbitrary location on the web by a malicious actor. For example, the redirected URL may point to a carefully imitated webpage of a genuine one, thus may lure a victim to submit its sign-in credentials.

## Recommendation

Avoid setting the entirety of URL or the domain part of it, which is obtained in any way from an external user, to the `location` header value, to keep redirection within the organization's domain. The URL to redirect the user to may be safely restricted by following one or more of the below strategies.

### Redirect to a URL from an internal allow-list

Select the URL from a predefined allow-list that is kept internal. It may be shared across organizations, but should be kept confidential to any external actors.

### Hardcode the domain part of the URL

If the URL to redirect the user to needs to be dependent upon a remote value, consider parameterizing only the request parameter portion and hardcode the rest of it, including the domain part. This way the redirection is kept within the organization.

### Use a server-side template engine

There can be a single URL to which all redirection of the same type can happen where the redirected page can be customized to the customer with the help from a template engine. The details of the page can be filled from the server-side, not the client side through a request parameter. This way the URL does not need to be parameterized in any way while also filling the need for a customized redirect page.

## Example

The following XSJS application sets the entire value of the location of its response to some URL retrieved from a request parameter.

``` javascript
let someParameterValue = requestParameters.get("someParameter");
$.response.status = $.net.http.OK;
$.response.headers.set("location", someParameterValue);
```

## References

* SAP: [Server-Side JavaScript Security Considerations](https://help.sap.com/docs/SAP_HANA_PLATFORM/d89d4595fae647eabc14002c0340a999/b5e65421b48c48fa87312a6023f4c414.html).
* SAP: [Server-Side JavaScript: Invalid Redirection](https://help.sap.com/docs/SAP_HANA_PLATFORM/d89d4595fae647eabc14002c0340a999/8c5ec75c27f543cb8b4c65c337b285ae.html).
* Mozilla: [Location](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Location).
* OWASP: [XSS Unvalidated Redirects and Forwards Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Unvalidated_Redirects_and_Forwards_Cheat_Sheet.html).
* Common Weakness Enumeration: [CWE-79](https://cwe.mitre.org/data/definitions/79.html).
* Common Weakness Enumeration: [CWE-116](https://cwe.mitre.org/data/definitions/116.html).
* Common Weakness Enumeration: [CWE-601](https://cwe.mitre.org/data/definitions/601.html).
* SAP XSJS Documentation: [$.web.WebRequest](https://help.sap.com/doc/3de842783af24336b6305a3c0223a369/2.0.03/en-US/$.web.WebRequest.html).
* SAP XSJS Documentation: [$.web.WebResponse](https://help.sap.com/doc/3de842783af24336b6305a3c0223a369/2.0.03/en-US/$.web.WebResponse.html).
