private import javascript
private import DataFlow
private import CDS

class CqlQueryBase extends VarRef {
  CqlQueryBase() {
    /* Made available as a global variable */
    exists(GlobalVariable queryBase |
      queryBase.getName() = ["SELECT", "INSERT", "DELETE", "UPDATE", "UPSERT"]
    |
      this = queryBase.getAReference()
    )
    or
    /* Imported from `cds.ql` */
    exists(CdsFacade cds, PropRef cdsDotQl |
      this.flow().getALocalSource() = cdsDotQl and
      cdsDotQl.getBase() = cds
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

Expr getRootReceiver(Expr e) {
  result = e and e instanceof VarRef
  or
  result = getRootReceiver(e.(DotExpr).getBase())
  or
  result = getRootReceiver(e.(MethodCallExpr).getReceiver())
  or
  result = getRootReceiver(e.(PropAccess).getBase())
  or
  result = getRootReceiver(e.(TaggedTemplateExpr).getTag())
}

newtype TCqlExpr =
  TaggedTemplate(TaggedTemplateExpr tagExpr) {
    exists(CqlQueryBase base | base = getRootReceiver(tagExpr))
  } or
  MethodCall(MethodCallExpr callExpr) {
    exists(CqlQueryBase base | base = getRootReceiver(callExpr))
  }

class CqlExpr extends TCqlExpr {
  TaggedTemplateExpr asTaggedTemplate() { this = TaggedTemplate(result) }

  MethodCallExpr asMethodCall() { this = MethodCall(result) }

  /**
   * Convert this `CqlExpr` into a `DotExpr`, i.e.
   * Get SELECT.from`Table` when given SELECT.from`Table`.where`cond`,
   * Get SELECT.from(table) when given SELECT.from(table).where`cond`,
   * Get SELECT.from`Table` when given SELECT.from`Table`.where(cond),
   * Get SELECT.from(table) when given SELECT.from(table).where(cond).
   */
  DotExpr asDotExpr() {
    result = this.asTaggedTemplate().getTag().(DotExpr)
    or
    result = this.asMethodCall().getCallee().(DotExpr)
  }

  string toString() {
    result = this.asTaggedTemplate().toString() or
    result = this.asMethodCall().toString()
  }

  Location getLocation() {
    result = this.asTaggedTemplate().getLocation() or
    result = this.asMethodCall().getLocation()
  }

  CqlQueryBase getCqlBase() {
    result = getRootReceiver(this.asTaggedTemplate()) or
    result = getRootReceiver(this.asMethodCall())
  }

  Expr getReceiver() {
    result = this.asMethodCall().getReceiver()
    or
    result = this.asTaggedTemplate().getTag().(DotExpr).getBase()
  }

  /* ========== Parent relationships ========== */

  Expr getParentExpr() {
    result = this.asMethodCall().getParentExpr() or
    result = this.asTaggedTemplate().getParentExpr()
  }

  CqlExpr getCqlParentExpr() {
    result.asTaggedTemplate() = this.asMethodCall().getParentExpr() or
    result.asMethodCall() = this.asTaggedTemplate().getParentExpr()
  }

  Expr getAnAncestorExpr() {
    result = this.asMethodCall().getParentExpr+() or
    result = this.asTaggedTemplate().getParentExpr+()
  }

  CqlExpr getAnAncestorCqlExpr() {
    result.asTaggedTemplate() = this.getAnAncestorExpr() or
    result.asMethodCall() = this.getAnAncestorExpr()
  }

  /* ========== Children relationships ========== */

  Expr getAChildExpr() {
    result = this.asMethodCall().getAChildExpr() or
    result = this.asTaggedTemplate().getAChildExpr()
  }

  CqlExpr getAChildCqlExpr() {
    result.asTaggedTemplate() = this.asMethodCall().getAChildExpr() or
    result.asMethodCall() = this.asTaggedTemplate().getAChildExpr()
  }

  Expr getADescendantExpr() {
    result = this.asMethodCall().getAChildExpr+() or
    result = this.asTaggedTemplate().getAChildExpr+()
  }

  CqlExpr getADescendantCqlExpr() {
    result.asTaggedTemplate() = this.getADescendantExpr() or
    result.asMethodCall() = this.getADescendantExpr()
  }

  /**
   * Matches the given CqlExpr to its method/property name, nested at arbitrary depth.
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
        any(CqlExpr ancestorSelect |
          ancestorSelect = this.getAnAncestorCqlExpr() and ancestorSelect.getCqlBase() = cqlSelect
        )
      )
    )
  }

  predicate selectWhere() { this.getAnAPIName() = "where" }

  predicate selectFrom() { this.getAnAPIName() = "from" }
}

class CqlInsertExpr extends CqlExpr {
  CqlInsertExpr() {
    exists(CqlInsertBase cqlInsert |
      this.getCqlBase() = cqlInsert and
      not exists(
        any(CqlExpr ancestorInsert |
          ancestorInsert = this.getAnAncestorCqlExpr() and ancestorInsert.getCqlBase() = cqlInsert
        )
      )
    )
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
  }
}
