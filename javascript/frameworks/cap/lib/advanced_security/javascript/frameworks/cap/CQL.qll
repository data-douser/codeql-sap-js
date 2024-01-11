import javascript
import DataFlow
import CDS::CDS

module CQL {
class CqlQueryBase extends VarRef {
  CqlQueryBase() {
    exists(string name | 
    this.getName() = name and
    name in ["SELECT", "INSERT", "DELETE", "UPDATE", "UPSERT"] and
    // Made available as a global variable
    exists(GlobalVariable queryBase |
      this = queryBase.getAReference()
    )
    or
    // Imported from `cds.ql` */
    exists(CdsFacade cds |
      cds.getMember("ql").getMember(name).getAValueReachableFromSource().asExpr() = this 
    )
    )
  }
}

class CqlSelectBase extends CqlQueryBase {
  CqlSelectBase() { this.getName() = "SELECT" }
}

class CqlInsertBase extends CqlQueryBase {
  CqlInsertBase() { this.getName() = "INSERT" }
}

class CqlDeleteBase extends CqlQueryBase {
  CqlDeleteBase() { this.getName() = "DELETE" }
}

class CqlUpdateBase extends CqlQueryBase {
  CqlUpdateBase() { this.getName() = "UPDATE" }
}

class CqlUpsertBase extends CqlQueryBase {
  CqlUpsertBase() { this.getName() = "UPSERT" }
}

/**
 * The cds-ql docs do not mention DELETE being a function acting as a shortcut to any underlying clause
 */
abstract class CqlQueryBaseCall extends CallExpr {
  // TODO: Express "It's a global function or a local function imported from cds.ql"
}

class CqlSelectBaseCall extends CqlQueryBaseCall {
  CqlSelectBaseCall() { this.getCalleeName() = "SELECT" }
}

class CqlInsertBaseCall extends CqlQueryBaseCall {
  CqlInsertBaseCall() { this.getCalleeName() = "INSERT" }
}

class CqlUpdateBaseCall extends CqlQueryBaseCall {
  CqlUpdateBaseCall() { this.getCalleeName() = "UPDATE" }
}

class CqlUpsertBaseCall extends CqlQueryBaseCall {
  CqlUpsertBaseCall() { this.getCalleeName() = "UPSERT" }
}

Expr getRootReceiver(Expr e) {
  result = e and
  (
    e instanceof VarRef
    or
    e instanceof CallExpr and not exists(e.(CallExpr).getReceiver())
  )
  or
  result = getRootReceiver(e.(DotExpr).getBase())
  or
  result = getRootReceiver(e.(MethodCallExpr).getReceiver())
  or
  result = getRootReceiver(e.(PropAccess).getBase())
  or
  result = getRootReceiver(e.(TaggedTemplateExpr).getTag())
}

newtype TCqlClause =
  MethodCall(MethodCallExpr callExpr) {
    exists(CqlQueryBase base | base = getRootReceiver(callExpr)) or
    exists(CqlQueryBaseCall call | call = getRootReceiver(callExpr))
  } or
  ShortcutCall(CqlQueryBaseCall callExpr)

class CqlClause extends TCqlClause {

  Expr asExpr(){
    result = this.asMethodCall()
    or 
    result = this.asShortcutCall()
  }

  Expr getArgument(){
    result = this.asMethodCall().getAnArgument()
    or 
    result = this.asShortcutCall().getAnArgument()
  }

  string getClauseName(){
    result = this.asMethodCall().getMethodName()
    or 
    (this.asShortcutCall().getCalleeName() = "SELECT" and
    result = "columns")
    or 
    (this.asShortcutCall().getCalleeName() in ["INSERT", "UPSERT"] and
    result = "entries")
    or 
    (this.asShortcutCall().getCalleeName() = "UPDATE" and
    result = "entity")
  }

  MethodCallExpr asMethodCall() { this = MethodCall(result) }

  CallExpr asShortcutCall() { this = ShortcutCall(result) }

  /**
   * Convert this `CqlClause` into a `DotExpr`, i.e.
   * `Get SELECT.from'Table' when given SELECT.from'Table'.wherecond`,
   */
  DotExpr asDotExpr() {
    result = this.asMethodCall().getCallee().(DotExpr)
  }

  string toString() {
    result = this.asMethodCall().toString() or
    result = this.asShortcutCall().toString()
  }

  Location getLocation() {
    result = this.asMethodCall().getLocation() or
    result = this.asShortcutCall().getLocation()
  }

  CqlQueryBase getCqlBase() {
    result = getRootReceiver(this.asMethodCall())
  }

  CqlQueryBaseCall getCqlBaseCall() {
    result = getRootReceiver(this.asMethodCall()).(CqlQueryBaseCall)
  }

  /** ========== Parent relationships ========== */
  Expr getParentExpr() {
    result = this.asMethodCall().getParentExpr() or
    result = this.asShortcutCall().getParentExpr()
  }

  /**
   * Possible cases for constructing a chain of clauses:
   * 
   * (looking at the terminal clause and its possible parent types as tuples: (this, parent))
   * 1) MethodCall.MethodCall
   *     - example `(SELECT.from(Table),  SELECT.from(Table).where("col1='*'"))`
   * 2) ShortcutCall.MethodCall
   *     - example `(SELECT("col1, col2"), SELECT("col1, col2").from("Table"))`
   * 
   * ShortcutCalls cannot be added to any clause chain other than the first position 
   * example - `SELECT("col1, col2").INSERT(col2)` is not valid
   */
  CqlClause getCqlParentExpr() {
    result.asMethodCall() =  this.asMethodCall().getParentExpr().getParentExpr()  
    or
    result.asMethodCall() = this.asShortcutCall().getParentExpr().getParentExpr()  
  }

  Expr getAnAncestorExpr() {
    result = this.asMethodCall().getParentExpr+() or
    result = this.asShortcutCall().getParentExpr+()
  }

  CqlClause getAnAncestorCqlClause() {
    result.asMethodCall() = this.getAnAncestorExpr() or
    result.asShortcutCall() = this.getAnAncestorExpr()
  }

  /** ========== Children relationships ========== */
  Expr getAChildExpr() {
    result = this.asMethodCall().getAChildExpr() or
    result = this.asShortcutCall().getAChildExpr()
  }

  /**
   * the same chain order logic as `getCqlParentExpr` but reversed
   */
  CqlClause getAChildCqlClause() {
    result.asMethodCall() = this.asMethodCall().getAChildExpr().getAChildExpr() or
    result.asShortcutCall() = this.asMethodCall().getAChildExpr().getAChildExpr()
  }

  Expr getADescendantExpr() {
    result = this.asMethodCall().getAChildExpr+() or
    result = this.asShortcutCall().getAChildExpr+()
  }

  CqlClause getADescendantCqlClause() {
    result.asMethodCall() = this.getADescendantExpr() or
    result.asShortcutCall() = this.getADescendantExpr()
  }

  /**
   * Matches the given `CqlClause` to its method/property name, nested at arbitrary depth.
   */
  string getAnAPIName() {
    result = this.asDotExpr().getPropertyName() or
    result = this.getADescendantCqlClause().getAnAPIName()
  }
}

/**
 * Call to`cds.db.run`
 */
//TODO: add awaits around SQLClauses
class CQLSink extends DataFlow::Node {
  CQLSink(){
    this = any(CdsFacade cds).getMember("db").getMember("run").getACall().getAnArgument()
  }
  
}
}