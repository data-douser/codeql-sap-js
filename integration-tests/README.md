# Integration tests

## xss-example

Not fully working, meaning you cannot run `ui5 serve` and play with the app, testing the XSS itself. We are having technical difficulties caused the ui5 tooling not cooperating well.

Anyways, here is the app's structure pertaining to the XSS vulnerability:

![Diagram of current app](./xss-example/diagram.svg "Diagram")

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

## xss-html-control
- `sap.ui.core.HTML` Control

## xss-js-view
- WORK IN PROGRESS

## xss-separate-renderer
- `renderer` property is set to a class name (a string)
- Renderer implemented in it's own module

## xss-separate-renderer-byname
- `renderer` property is unassigned
- Renderer implemented in it's own module with naming convention `<CustomControl>Renderer`