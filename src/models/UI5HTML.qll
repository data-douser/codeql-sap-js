private import javascript
private import DataFlow

/*
 * Useful ones:
 *   IframeElement: https://codeql.github.com/codeql-standard-libraries/javascript/semmle/javascript/HTML.qll/type.HTML$HTML$IframeElement.html
 *   ScriptElement: https://codeql.github.com/codeql-standard-libraries/javascript/semmle/javascript/HTML.qll/type.HTML$HTML$ScriptElement.html
 */

/**
 * Check the value of this page's `frameOptions` as declared in HTML.
 * Setting `frameOptions` to `deny` prohibits framing altogether, at all. E.g.:
 * ```html
 *  <script id='sap-ui-bootstrap'
 *	  src='resources/sap-ui-core.js'
 *	  data-sap-ui-frameOptions='deny'>
 *  </script>
 * ```
 */
string htmlFrameOptions(HTML::ScriptElement scriptTag) {
  result = scriptTag.getAttributeByName("data-sap-ui-frameOptions").getValue()
}

/**
 * Check the value of this page's `frameOptions` as declared in JavaScript.
 * Setting `frameOptions` to `trusted` allows framing from the same origin. E.g.:
 * ```js
 * window["sap-ui-config"] = {
 *     frameOptions: 'trusted',
 *     ...
 * }
 * ```
 * or
 * ```js
 * window["sap-ui-config"].frameOptions = 'trusted';
 * ```
 */
string jsFrameOptions(PropRef windowDecl) {
  /*
   * window["sap-ui-config"] = {
   *     frameOptions: 'trusted',
   *     ...
   * }
   */

  windowDecl.getPropertyName() = "sap-ui-config" and
  result =
    windowDecl
        .(PropWrite)
        .getRhs()
        .(ObjectLiteralNode)
        .getAPropertySource("frameOptions")
        .asExpr()
        .(StringLiteral)
        .getValue()
  or
  /*
   * window["sap-ui-config"].frameOptions = 'trusted';
   */

  exists(PropWrite windowFrameOptions |
    windowDecl.getALocalSource().flowsTo(windowFrameOptions) and
    result = windowFrameOptions.getRhs().asExpr().(StringLiteral).getValue()
  )
}
