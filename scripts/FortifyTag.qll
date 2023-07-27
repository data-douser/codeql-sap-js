import javascript

abstract class FortifyTag extends JSDocTag {
  FortifyTag() {
    exists(JSDoc doc |
      this = doc.getATagByTitle("SecSource") or
      this = doc.getATagByTitle("SecSink") or
      this = doc.getATagByTitle("SecValidate") or
      this = doc.getATagByTitle("SecPassthrough")
    )
  }

  string getFortifySpec() {
    result = this.getDescription().splitAt("\n", 0).regexpCapture(".*(\\{.+\\}).*", 1)
  }

  string getFortifySpecContents() { result = this.getFortifySpec().regexpCapture("\\{(.+)\\}", 1) }

  DocumentedObject getDocumentedObject() { result.getDocumentation() = this.getJSDocComment() }

  abstract string getYamlRow();
}

class FortifySourceTag extends FortifyTag {
  FortifySourceTag() { exists(JSDoc doc | this = doc.getATagByTitle("SecSource")) }

  string getOutSpec() {
    if this.getFortifySpecContents().splitAt("|", 0) = "return"
    then result = "ReturnValue"
    else result = ""
  }

  string getFlags() {
    if not exists(this.getFortifySpecContents().splitAt("|", 1))
    then result = ""
    else result = this.getFortifySpecContents().splitAt("|", 1)
  }

  predicate isJQuery() { this.getFile().getStem().prefix(6) = "jquery" }

  predicate hasNameTag() { exists(this.getJSDocComment().getATagByTitle("name")) }

  string getNameTag() { result = this.getJSDocComment().getATagByTitle("name").getName() }

  string getModuleName() {
    /* "~/openui5/src/sap.ui.core/src/jquery.sap.sjax.js" */
    if this.isJQuery() or this.hasNameTag()
    then result = "global"
    else
      /* "~/openui5/src/sap.ui.core/src/sap/base/util/UriParameters.js" */
      result =
        this.getFile()
            .getAbsolutePath()
            .regexpCapture(".*(sap\\/[a-zA-Z]+\\/.*)", 1)
            .regexpCapture("(.*)\\.js", 1)
  }

  string getAPILangString() {
    if this.isJQuery()
    then
      if this.hasNameTag()
      then
        result =
          this.getNameTag().replaceAll("#", ".").regexpReplaceAll("([a-zA-Z]+)", "Member[$1]") + "."
            + this.getOutSpec()
      else
        result =
          this.getDocumentedObject().getExprString().regexpReplaceAll("([a-zA-Z]+)", "Member[$1]") +
            "." + this.getOutSpec()
    else
      exists(DocumentedObject object | object = this.getDocumentedObject() |
        if object.isNotAMethod()
        then result = "Instance.Member[" + object.getExprString() + "]"
        else result = "Instance.Member[" + object.getExprString() + "]" + "." + this.getOutSpec()
      )
  }

  override string getYamlRow() {
    result =
      "[\"" + this.getModuleName() + "\", " + "\"" + this.getAPILangString() + "\", " + "\"" +
        this.getFlags() + "\"" + "]"
  }
}

class FortifySinkTag extends FortifyTag {
  FortifySinkTag() { exists(JSDoc doc | this = doc.getATagByTitle("SecSink")) }

  string getInSpec() {
    if this.getFortifySpecContents().splitAt("|", 0).splitAt(" ").regexpMatch(".*\\*.*")
    then result = this.getFortifySpecContents().splitAt("|", 0).splitAt(" ").replaceAll("*", "0..")
    else
      if count(this.getFortifySpecContents().splitAt("|", 0).splitAt(" ").toInt()) = 1
      then result = this.getFortifySpecContents().splitAt("|", 0).splitAt(" ")
      else
        result =
          min(this.getFortifySpecContents().splitAt("|", 0).splitAt(" ").toInt()) + ".." +
            max(this.getFortifySpecContents().splitAt("|", 0).splitAt(" ").toInt())
  }

  string getFlags() {
    if not exists(this.getFortifySpecContents().splitAt("|", 1))
    then result = ""
    else result = this.getFortifySpecContents().splitAt("|", 1)
  }

  predicate hasNameTag() { exists(this.getJSDocComment().getATagByTitle("name")) }

  string getNameTag() { result = this.getJSDocComment().getATagByTitle("name").getName() }

  predicate isJQuery() { this.getFile().getStem().prefix(6) = "jquery" }

  string getModuleName() {
    /* "~/openui5/src/sap.ui.core/src/jquery.sap.sjax.js" */
    if this.isJQuery() or this.hasNameTag()
    then result = "global"
    else
      /* "~/openui5/src/sap.ui.core/src/sap/base/util/UriParameters.js" */
      result =
        this.getFile()
            .getAbsolutePath()
            .regexpCapture(".*(sap\\/[a-zA-Z]+\\/.*)", 1)
            .regexpCapture("(.*)\\.js", 1)
  }

  string getAPILangString() {
    if this.isJQuery()
    then
      if this.hasNameTag()
      then
        result =
          this.getNameTag().replaceAll("#", ".").regexpReplaceAll("([a-zA-Z]+)", "Member[$1]") +
            ".Argument[" + this.getInSpec() + "]"
      else
        result =
          this.getDocumentedObject().getExprString().regexpReplaceAll("([a-zA-Z]+)", "Member[$1]") +
            ".Argument[" + this.getInSpec() + "]"
    else
      exists(DocumentedObject object | object = this.getDocumentedObject() |
        if object.isNotAMethod()
        then result = "Instance.Member[" + object.getExprString() + "]"
        else
          result =
            "Instance.Member[" + object.getExprString() + "].Argument[" + this.getInSpec() + "]"
      )
  }

  override string getYamlRow() {
    result =
      "[\"" + this.getModuleName() + "\", " + "\"" + this.getAPILangString() + "\", " + "\"" +
        this.getFlags() + "\"" + "]"
  }
}

// class FortifyValidateTag extends FortifyTag {
//   FortifyValidateTag() { exists(JSDoc doc | this = doc.getATagByTitle("SecValidate")) }
//   string getInSpec() {
//     result = this.getFortifySpecContents().splitAt("|", 0).splitAt(" ").replaceAll("*", "0..")
//   }
//   string getOutSpec() {
//     if this.getFortifySpecContents().splitAt("|", 1) = "return"
//     then result = "ReturnValue"
//     else result = ""
//   }
//   string getFlags() {
//     if not exists(this.getFortifySpecContents().splitAt("|", 2))
//     then result = ""
//     else result = this.getFortifySpecContents().splitAt("|", 2)
//   }
//   predicate hasNameTag() { exists(this.getJSDocComment().getATagByTitle("name")) }
//   string getNameTag() { result = this.getJSDocComment().getATagByTitle("name").getName() }
//   predicate isJQuery() { this.getFile().getStem().prefix(6) = "jquery" }
//   string getModuleName() {
//     /* "~/openui5/src/sap.ui.core/src/jquery.sap.sjax.js" */
//     if this.isJQuery() or this.hasNameTag()
//     then result = "global"
//     else
//       /* "~/openui5/src/sap.ui.core/src/sap/base/util/UriParameters.js" */
//       result =
//         this.getFile()
//             .getParentContainer()
//             .getAbsolutePath()
//             .regexpCapture(".*(sap\\/[a-zA-Z]+\\/.*)", 1)
//   }
// string getAPILangStringInSpec() { result = "Argument[" + this.getInSpec() + "]" }
// string getAPILangStringOutSpec() { result = this.getOutSpec() }
// override string getYamlRow() {
//   result =
//   "[\"" + this.getModuleName() + "\"," + "\"taint\"]"
// }
// }
class FortifyPassthroughTag extends FortifyTag {
  FortifyPassthroughTag() { exists(JSDoc doc | this = doc.getATagByTitle("SecPassthrough")) }

  string getInSpec() {
    result = this.getFortifySpecContents().splitAt("|", 0).splitAt(" ").replaceAll("*", "0..")
  }

  string getOutSpec() {
    if this.getFortifySpecContents().splitAt("|", 1) = "return"
    then result = "ReturnValue"
    else result = ""
  }

  string getFlags() {
    if not exists(this.getFortifySpecContents().splitAt("|", 2))
    then result = ""
    else result = this.getFortifySpecContents().splitAt("|", 2)
  }

  predicate isJQuery() { this.getFile().getStem().prefix(6) = "jquery" }

  string getModuleName() {
    /* "~/openui5/src/sap.ui.core/src/jquery.sap.sjax.js" */
    if this.isJQuery()
    then result = "global"
    else
      /* "~/openui5/src/sap.ui.core/src/sap/base/util/UriParameters.js" */
      result =
        this.getFile()
            .getAbsolutePath()
            .regexpCapture(".*(sap/[a-zA-Z]+/.*)", 1)
            .regexpCapture("(.*)\\.js", 1)
  }

  string getPathString() {
    if this.isJQuery()
    then
      result =
        this.getDocumentedObject().getExprString().regexpReplaceAll("([a-zA-Z]+)", "Member[$1]")
    else result = ""
  }

  string getAPILangStringInSpec() { result = "Argument[" + this.getInSpec() + "]" }

  string getAPILangStringOutSpec() { result = this.getOutSpec() }

  override string getYamlRow() {
    result =
      "[\"" + this.getModuleName() + "\", " + "\"" + this.getPathString() + "\", " + "\"" +
        this.getAPILangStringInSpec() + "\", " + "\"" + this.getAPILangStringOutSpec() + "\", " +
        "\"taint\"]"
  }
}

class DocumentedObject extends Expr {
  DocumentedObject() {
    this instanceof AssignExpr
    or
    this instanceof VarDecl
    or
    this instanceof ObjectExpr and this.getParent() instanceof Property
  }

  string getExprString() {
    this instanceof AssignExpr and
    exists(Expr lhs | lhs = this.(AssignExpr).getLhs() |
      (
        if lhs.(DotExpr).getBase().toString() = "jQuery.sap"
        then result = lhs.(DotExpr).getQualifiedName()
        else result = lhs.(DotExpr).getPropertyName()
      )
    )
    or
    this instanceof ObjectExpr and
    result = this.getParent().(Property).getAChildExpr().(Label).getName()
    or
    this instanceof VarDecl and result = this.(VarDecl).getName()
  }

  predicate isNotAMethod() { this instanceof ObjectExpr }
}
