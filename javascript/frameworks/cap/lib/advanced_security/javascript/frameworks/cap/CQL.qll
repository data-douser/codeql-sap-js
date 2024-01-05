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

abstract class CqlQueryBaseCall extends CallExpr {
  // TODO: Express "It's a global function or a local function imported from cds.ql"
}

class CqlSelectBaseCall extends CqlQueryBaseCall {
  CqlSelectBaseCall() { this.getCalleeName() = "SELECT" }
}

class CqlInsertBaseCall extends CqlQueryBaseCall {
  CqlInsertBaseCall() { this.getCalleeName() = "INSERT" }
}

class CqlDeleteBaseCall extends CqlQueryBaseCall {
  CqlDeleteBaseCall() { this.getCalleeName() = "DELETE" }
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

newtype TCqlExprClause =
  TaggedTemplate(TaggedTemplateExpr tagExpr) {
    exists(CqlQueryBase base | base = getRootReceiver(tagExpr)) or
    exists(CqlQueryBaseCall call | call = getRootReceiver(tagExpr))
  } or
  MethodCall(MethodCallExpr callExpr) {
    exists(CqlQueryBase base | base = getRootReceiver(callExpr)) or
    exists(CqlQueryBaseCall call | call = getRootReceiver(callExpr))
  } or
  ShortcutCall(CqlQueryBaseCall callExpr)

class CqlExpr extends TCqlExprClause {
  TaggedTemplateExpr asTaggedTemplate() { this = TaggedTemplate(result) }

  MethodCallExpr asMethodCall() { this = MethodCall(result) }

  CallExpr asShortcutCall() { this = ShortcutCall(result) }

  /**
   * Convert this `CqlExpr` into a `DotExpr`, i.e.
   * `Get SELECT.from'Table' when given SELECT.from'Table'.wherecond`,
   */
  DotExpr asDotExpr() {
    result = this.asTaggedTemplate().getTag().(DotExpr)
    or
    result = this.asMethodCall().getCallee().(DotExpr)
  }

  string toString() {
    result = this.asTaggedTemplate().toString() or
    result = this.asMethodCall().toString() or
    result = this.asShortcutCall().toString()
  }

  Location getLocation() {
    result = this.asTaggedTemplate().getLocation() or
    result = this.asMethodCall().getLocation() or
    result = this.asShortcutCall().getLocation()
  }

  CqlQueryBase getCqlBase() {
    result = getRootReceiver(this.asTaggedTemplate()) or
    result = getRootReceiver(this.asMethodCall())
  }

  CqlQueryBaseCall getCqlBaseCall() {
    result = getRootReceiver(this.asTaggedTemplate()).(CqlQueryBaseCall) or
    result = getRootReceiver(this.asMethodCall()).(CqlQueryBaseCall)
  }

  Expr getReceiver() {
    result = this.asMethodCall().getReceiver()
    or
    result = this.asTaggedTemplate().getTag().(DotExpr).getBase()
  }

  /** ========== Parent relationships ========== */
  Expr getParentExpr() {
    result = this.asMethodCall().getParentExpr() or
    result = this.asTaggedTemplate().getParentExpr() or
    result = this.asShortcutCall().getParentExpr()
  }

  CqlExpr getCqlParentExpr() {
    result.asTaggedTemplate() = this.asMethodCall().getParentExpr() or
    result.asMethodCall() = this.asTaggedTemplate().getParentExpr() or
    result.asShortcutCall() = this.asShortcutCall().getParentExpr()
  }

  Expr getAnAncestorExpr() {
    result = this.asMethodCall().getParentExpr+() or
    result = this.asTaggedTemplate().getParentExpr+() or
    result = this.asShortcutCall().getParentExpr+()
  }

  CqlExpr getAnAncestorCqlExpr() {
    result.asTaggedTemplate() = this.getAnAncestorExpr() or
    result.asMethodCall() = this.getAnAncestorExpr() or
    result.asShortcutCall() = this.getAnAncestorExpr()
  }

  /** ========== Children relationships ========== */
  Expr getAChildExpr() {
    result = this.asMethodCall().getAChildExpr() or
    result = this.asTaggedTemplate().getAChildExpr() or
    result = this.asShortcutCall().getAChildExpr()
  }

  CqlExpr getAChildCqlExpr() {
    result.asTaggedTemplate() = this.asMethodCall().getAChildExpr() or
    result.asMethodCall() = this.asTaggedTemplate().getAChildExpr() or
    result.asShortcutCall() = this.asShortcutCall().getAChildExpr()
  }

  Expr getADescendantExpr() {
    result = this.asMethodCall().getAChildExpr+() or
    result = this.asTaggedTemplate().getAChildExpr+() or
    result = this.asShortcutCall().getAChildExpr+()
  }

  CqlExpr getADescendantCqlExpr() {
    result.asTaggedTemplate() = this.getADescendantExpr() or
    result.asMethodCall() = this.getADescendantExpr() or
    result.asShortcutCall() = this.getADescendantExpr()
  }

  /**
   * Matches the given `CqlExpr` to its method/property name, nested at arbitrary depth.
   */
  string getAnAPIName() {
    result = this.asDotExpr().getPropertyName() or
    result = this.getADescendantCqlExpr().getAnAPIName()
  }
}

class CqlSelectExpr extends CqlExpr {
  CqlSelectExpr() {
    exists(CqlSelectBase cqlSelect |
      this.getCqlBase() = cqlSelect and
      not exists(
        CqlExpr ancestorSelect |
          ancestorSelect = this.getAnAncestorCqlExpr() and ancestorSelect.getCqlBase() = cqlSelect
      )
    )
    or
    this.getCqlBaseCall() instanceof CqlSelectBaseCall
  }

  predicate selectWhere() { this.getAnAPIName() = "where" }

  predicate selectFrom() { this.getAnAPIName() = "from" }

  predicate selectColumns() {
    this.getAnAPIName() = "columns"
    or
    // SELECT itself is a shortcut of SELECT.columns
    this.getCqlBaseCall() instanceof CqlSelectBaseCall
  }
}

class CqlInsertExpr extends CqlExpr {
  CqlInsertExpr() {
    exists(CqlInsertBase cqlInsert |
      this.getCqlBase() = cqlInsert and
      not exists(
        CqlExpr ancestorInsert |
          ancestorInsert = this.getAnAncestorCqlExpr() and ancestorInsert.getCqlBase() = cqlInsert
      )
    )
    or
    this.getCqlBaseCall() instanceof CqlInsertBaseCall
  }

  predicate insertEntries() {
    this.getAnAPIName() = "entries"
    or
    // INSERT itself is a shortcut of INSERT.entries
    this.getCqlBaseCall() instanceof CqlInsertBaseCall
  }
}

class CqlDeleteExpr extends CqlExpr {
  CqlDeleteExpr() {
    exists(CqlDeleteBase cqlDelete |
      this.getCqlBase() = cqlDelete and
      not exists(
        any(CqlExpr ancestorDelete |
          ancestorDelete = this.getAnAncestorCqlExpr() and ancestorDelete.getCqlBase() = cqlDelete
        )
      )
    )
  }
}

class CqlUpdateExpr extends CqlExpr {
  CqlUpdateExpr() {
    exists(CqlUpdateBase cqlUpdate |
      this.getCqlBase() = cqlUpdate and
      not exists(
        any(CqlExpr ancestorUpdate |
          ancestorUpdate = this.getAnAncestorCqlExpr() and ancestorUpdate.getCqlBase() = cqlUpdate
        )
      )
    )
    or
    this.getCqlBaseCall() instanceof CqlUpdateBaseCall
  }

  predicate updateEntity() {
    this.getAnAPIName() = "entity"
    or
    // UPDATE itself is a shortcut of UPDATE.entity
    this.getCqlBaseCall() instanceof CqlUpdateBaseCall
  }
}

class CqlUpsertExpr extends CqlExpr {
  CqlUpsertExpr() {
    exists(CqlUpsertBase cqlUpsert |
      this.getCqlBase() = cqlUpsert and
      not exists(
        any(CqlExpr ancestorUpsert |
          ancestorUpsert = this.getAnAncestorCqlExpr() and ancestorUpsert.getCqlBase() = cqlUpsert
        )
      )
    )
    or
    this.getCqlBaseCall() instanceof CqlUpsertBaseCall
  }

  predicate upsertEntries() {
    this.getAnAPIName() = "entries"
    or
    // UPSERT itself is a shortcut of UPSERT.entries
    this.getCqlBaseCall() instanceof CqlUpsertBaseCall
  }
}
}