private import javascript
private import DataFlow

predicate isHTMLFile(HTML::HtmlFile html) { any() }

/*
 * Useful ones:
 *   IframeElement: https://codeql.github.com/codeql-standard-libraries/javascript/semmle/javascript/HTML.qll/type.HTML$HTML$IframeElement.html
 *   ScriptElement: https://codeql.github.com/codeql-standard-libraries/javascript/semmle/javascript/HTML.qll/type.HTML$HTML$ScriptElement.html
 */

/**
 * This prohibits framing altogether, at all. E.g.:
 * ```
 *  <script id='sap-ui-bootstrap'
 *	  src='resources/sap-ui-core.js'
 *	  data-sap-ui-frameOptions='deny'>
 *  </script>
 * ```
 */
string htmlFrameOptions(HTML::ScriptElement scriptTag) {
  result = scriptTag.getAttributeByName("data-sap-ui-frameOptions").getValue()
}

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
