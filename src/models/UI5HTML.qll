private import javascript
private import DataFlow

newtype TFrameOptions =
  HtmlFrameOptions(HTML::ScriptElement scriptElement) or
  JsFrameOptions(DataFlow::PropRef windowDecl)

class FrameOptions extends TFrameOptions {
  HTML::ScriptElement asHtmlFrameOptions() { this = HtmlFrameOptions(result) }

  DataFlow::PropRef asJsFrameOptions() { this = JsFrameOptions(result) }

  private string getHtmlFrameOptions() {
    /*
     * Check the value of this page's `frameOptions` as declared in HTML.
     * Setting `frameOptions` to `deny` prohibits framing altogether, at all. E.g.:
     * ```html
     *  <script id='sap-ui-bootstrap'
     * 	  src='resources/sap-ui-core.js'
     * 	  data-sap-ui-frameOptions='deny'>
     *  </script>
     * ```
     */

    result = this.asHtmlFrameOptions().getAttributeByName("data-sap-ui-frameOptions").getValue()
    or
    /*
     * Check the value of this page's `frameOptions` as declared in JavaScript.
     * Setting `frameOptions` to `trusted` allows framing from the same origin. E.g.:
     * ```js
     * window["sap-ui-config"] = {
     *     frameOptions: 'trusted',
     *     ...
     * }
     * ```
     */

    exists(DataFlow::PropRef windowDecl | windowDecl = this.asJsFrameOptions() |
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
       * ```js
       * window["sap-ui-config"].frameOptions = 'trusted';
       * ```
       */

      exists(PropWrite windowFrameOptions |
        windowDecl.getALocalSource().flowsTo(windowFrameOptions) and
        result = windowFrameOptions.getRhs().asExpr().(StringLiteral).getValue()
      )
    )
  }

  predicate allowsSharedOriginEmbedding() { this.getHtmlFrameOptions() = "trusted" }

  predicate deniesEmbedding() { this.getHtmlFrameOptions() = "deny" }

  predicate allowsAllOriginEmbedding() { this.getHtmlFrameOptions() = "allow" }

  string toString() {
    result = this.asHtmlFrameOptions().toString() or
    result = this.asJsFrameOptions().toString()
  }
}

/**
 * Holds if the frame options are left untouched as the default value `trusted`.
 */
predicate thereIsNoFrameOptionSet() {
  not exists(FrameOptions frameOptions |
    frameOptions.allowsSharedOriginEmbedding() or
    frameOptions.deniesEmbedding() or
    frameOptions.allowsAllOriginEmbedding()
  )
}
