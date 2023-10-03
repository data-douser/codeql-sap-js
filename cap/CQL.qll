private import javascript
private import DataFlow
private import CAPModels

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

/**
 * Holds if a `DotExpr` ultimately accesses a `SELECT` variable, e.g.
 * ```js
 * SELECT.from
 * SELECT.one.from
 * SELECT.distinct.from
 * ```
 */
private predicate accessesSelect(DotExpr dot) {
  dot.accesses(any(VarRef var | var.getName() = "SELECT"),
    [
      "one", "distinct", "columns", "from", "alias", "where", "having", "groupBy", "orderBy",
      "limit", "forUpdate", "forShareLock"
    ])
  or
  dot.getPropertyName() =
    [
      "one", "distinct", "columns", "from", "alias", "where", "having", "groupBy", "orderBy",
      "limit", "forUpdate", "forShareLock"
    ] and
  accessesSelect(dot.getAChildExpr())
}

/**
 * Method call `SELECT` CQL query expressions, e.g.
 * ```js
 * SELECT.from(Table)
 * SELECT.distinct.from(Table);
 * SELECT.from`Table`.where("col1='*'");
 * SELECT.from(Table).having("col1='*'");
 * ```
 */
private predicate isMethodCallSelect(MethodCallExpr callExpr) {
  callExpr.getCalleeName() =
    [
      "columns", "from", "alias", "where", "having", "groupBy", "orderBy", "limit", "forUpdate",
      "forShareLock"
    ] and
  exists(Expr receiver | receiver = callExpr.getCallee() |
    /*
     * Only property accesses are left up to SELECT, e.g.
     * SELECT.x.y. ...z(cond)
     */

    accessesSelect(receiver)
    or
    /*
     * The immediate prefix is a TaggedTemplateExpr:
     * SELECT.x. ... .z`cond1`.w(cond2)
     */

    exists(TaggedTemplateExpr nestedTaggingExpr |
      receiver.(DotExpr).accesses(nestedTaggingExpr, _)
    |
      isTaggedTemplateSelect(nestedTaggingExpr)
    )
    or
    /*
     * The immediate prefix is a MethodCallExpr:
     * SELECT.x. ... .z(cond1).w(cond2)
     */

    exists(MethodCallExpr nestedCallExpr | receiver.(DotExpr).accesses(nestedCallExpr, _) |
      isMethodCallSelect(nestedCallExpr)
    )
  )
}

/**
 * Tagged `SELECT` CQL query expressions, e.g.
 * ```js
 * SELECT.from`Table`
 * SELECT.distinct.from`Table`;
 * SELECT.from(Table).where`"col1='*'"`;
 * SELECT.from`Table`.having`"col1='*'"`;  ==> "Select having call"
 *
 *
 * SELECT.having`"col1='*'".`from`Table`; ==> "Select from call", if we omit `having` from consideration? getLocation()
 *
 *
 * ```
 */
private predicate isTaggedTemplateSelect(TaggedTemplateExpr tagExpr) {
  exists(Expr taggingExpr |
    taggingExpr = tagExpr.getTag() and
    taggingExpr.(DotExpr).getPropertyName() =
      [
        "columns", "from", "alias", "where", "having", "groupBy", "orderBy", "limit", "forUpdate",
        "forShareLock"
      ]
  |
    /*
     * Only property accesses are left up to SELECT, e.g.
     * SELECT.x.y. ...z`cond`
     */

    accessesSelect(taggingExpr)
    or
    /*
     * The immediate prefix is a TaggedTemplateExpr:
     * SELECT.x. ... .z`cond1`.w`cond2`
     */

    exists(TaggedTemplateExpr nestedTaggingExpr |
      taggingExpr.(DotExpr).accesses(nestedTaggingExpr, _)
    |
      isTaggedTemplateSelect(nestedTaggingExpr)
    )
    or
    /*
     * The immediate prefix is a MethodCallExpr:
     * SELECT.x. ... .z(cond1).w`cond2`
     */

    exists(MethodCallExpr nestedCallExpr | taggingExpr.(DotExpr).accesses(nestedCallExpr, _) |
      isMethodCallSelect(nestedCallExpr)
    )
  )
}

private predicate accessesInsert(DotExpr dot) {
  dot.accesses(any(VarRef var | var.getName() = "INSERT"),
    ["into", "entries", "values", "rows", "as"])
  or
  dot.getPropertyName() = ["into", "entries", "values", "rows", "as"] and
  accessesInsert(dot.getAChildExpr())
}

private predicate isMethodCallInsert(MethodCallExpr callExpr) {
  callExpr.getCalleeName() = ["into", "entries", "values", "rows", "as"] and
  exists(Expr receiver | receiver = callExpr.getCallee() |
    accessesInsert(receiver)
    or
    exists(TaggedTemplateExpr nestedTaggingExpr |
      receiver.(DotExpr).accesses(nestedTaggingExpr, _)
    |
      isTaggedTemplateInsert(nestedTaggingExpr)
    )
    or
    exists(MethodCallExpr nestedCallExpr | receiver.(DotExpr).accesses(nestedCallExpr, _) |
      isMethodCallInsert(nestedCallExpr)
    )
  )
}

private predicate isTaggedTemplateInsert(TaggedTemplateExpr tagExpr) {
  exists(Expr taggingExpr |
    taggingExpr = tagExpr.getTag() and
    taggingExpr.(DotExpr).getPropertyName() = ["into", "entries", "values", "rows", "as"]
  |
    accessesInsert(taggingExpr)
    or
    exists(TaggedTemplateExpr nestedTaggingExpr |
      taggingExpr.(DotExpr).accesses(nestedTaggingExpr, _)
    |
      isTaggedTemplateInsert(nestedTaggingExpr)
    )
    or
    exists(MethodCallExpr nestedCallExpr | taggingExpr.(DotExpr).accesses(nestedCallExpr, _) |
      isMethodCallInsert(nestedCallExpr)
    )
  )
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

  Expr getParent() {
    result = this.asMethodCall().getParent() or
    result = this.asTaggedTemplate().getParent()
  }
}

class CqlSelectExpr extends CqlExpr {
  CqlSelectExpr() {
    exists(CqlSelectBase cqlSelect |
      this.getCqlBase() = cqlSelect and
      not this.getParent() instanceof TaggedTemplateExpr and
      not this.getParent() instanceof MethodCallExpr
    )
  }

  predicate selectWhere() {
    this.asMethodCall().getMethodName() = "where" or
    this.asTaggedTemplate().getTag().(DotExpr).getPropertyName() = "where"
  }

  predicate selectFrom() {
    this.asMethodCall().getMethodName() = "from" or
    this.asTaggedTemplate().getTag().(DotExpr).getPropertyName() = "from"
  }
}

class CqlInsertExpr extends CqlExpr {
  CqlInsertExpr() { exists(CqlInsertBase cqlInsert | this.getCqlBase() = cqlInsert) }
}
// class CqlDeleteExpr extends CqlExpr {
//   CqlDeleteExpr() { any() }
// }
// class CqlUpdateExpr extends CqlExpr {
//   CqlUpdateExpr() { any() }
// }
// class CqlUpsertExpr extends CqlExpr {
//   CqlUpsertExpr() { any() }
// }
