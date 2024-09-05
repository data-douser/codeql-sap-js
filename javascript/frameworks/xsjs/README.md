# SAP XSJS with CodeQL

CodeQL queries and supporting models for the SAP XSJS JavaScript framework

### Queries
- [XSS](src/XSJSReflectedXss/XSJSReflectedXss.ql)
- [SQL Injection](src/XSJSSqlInjection/XSJSSqlInjection.ql)
- [Log Injection](src/UI5LogInjection/UI5LogInjection.ql)
- [URL Rediraction](src/XSJSUrlRedirect/XSJSUrlRedirect.ql)
- [Clickjacking](src/UI5Clickjacking/UI5Clickjacking.ql)
- [Authentication Issues](src/XSJSAuthentication/XSJSAuthentication.ql)
- [Disabled CSRF Protection](src/XSJSCsrfDisabled/XSJSCsrfDisabled.ql)

### Modeled XSJS framework elements (From CodeQL v2.18.4)
 - XSJS NPM components
 - XSJSLib modules
