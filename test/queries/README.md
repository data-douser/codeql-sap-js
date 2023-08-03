# Queries unit tests

All XSS examples run locally using the [UI5 tooling](https://sap.github.io/ui5-tooling/stable/)

## log-html-control-df
- log-injection in the controller

## xss-custom-control-api1
- custom Control
- classic string-based API
- `renderer` property is set to a render function

## xss-custom-control-api2
- custom Control
- DOM-like API
- `renderer` property is set to an object literal 

## xss-custom-control-jquery
- custom Control declared using JQuery

## xss-custom-control-property-sanitized
- custom Control
- DOM-like API
- the type of the control property `text` is set to `int` (sanitized)
- the sanitizer is not affecting the log-injection

## xss-custom-control-property-sanitized
- custom Control
- DOM-like API
- the value of `text` is sanitized using `sap/base/security/encodeXML`


## xss-html-control
- `sap.ui.core.HTML` Control

## xss-html-control-df
- `sap.ui.core.HTML` Control
- dataflow in the controller

## xss-html-control-oneway
- `sap.ui.core.HTML` Control
- one-way binding makes the xss fail

## xss-html-external-model
- `sap.ui.core.HTML` Control
- controller model as external `.json` file

## xss-html-view
- `sap.ui.core.mvc.HTMLView` View

## xss-js-view
- `sap.ui.core.mvc.JSView` View

## xss-json-view
- `sap.ui.core.mvc.JSONView` View

## xss-log-custom-control-sanitized
- the value of `text` is sanitized using `sap/base/security/encodeXML`
- the sanitizer is not affecting the log-injection

## xss-separate-renderer
- `renderer` property is set to a class name (a string)
- Renderer implemented in it's own module

## xss-separate-renderer-byname
- `renderer` property is unassigned
- Renderer implemented in its own module with naming convention `<CustomControl>Renderer`
