private import javascript
private import DataFlow

/* TODO: Query bases */
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
 * SELECT.from`Table`.having`"col1='*'"`;
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

newtype TCqlExpr =
  TaggedTemplate(TaggedTemplateExpr tagExpr) or
  MethodCall(MethodCallExpr callExpr)

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
}

class CqlSelectExpr extends CqlExpr {
  CqlSelectExpr() {
    isMethodCallSelect(this.asMethodCall()) or isTaggedTemplateSelect(this.asTaggedTemplate())
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
  CqlInsertExpr() { isMethodCallInsert(this.asMethodCall()) }
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
