# Broken XSJS authentication

If you choose to use server-side JavaScript to write your application code, you need to bear in mind the potential for (and risk of) attack against authentication infrastructure. Leaks or flaws in the authentication or session management functions allow attackers to impersonate users and gain access to unauthorized systems and data.

## Recommendation

Use the built-in SAP HANA XS authentication mechanism and session management (cookies). For example, use the "authentication" keyword to enable an authentication method and set it according to the authentication method you want implement, for example: SAP logon ticket, form-based, or basic (user name and password) in the application's .xsaccess file, which ensures that all objects in the application path are available only to authenticated users.

## Example

The following `xs-app.json` fragment shows disabled XSJS authentication.

``` javascript
{
  "welcomeFile": "index.html",
  "authenticationMethod": "none",
  "routes": [ ...
```

## References

* SAP: [Server-Side JavaScript Security Considerations](https://help.sap.com/docs/SAP_HANA_PLATFORM/d89d4595fae647eabc14002c0340a999/2040c1b7e478448cb9904c55ac06cac8.html).
* Common Weakness Enumeration: [CWE-287](https://cwe.mitre.org/data/definitions/287.html).
