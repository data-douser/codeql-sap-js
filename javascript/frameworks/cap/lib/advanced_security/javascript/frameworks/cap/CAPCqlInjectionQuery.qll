import javascript
import semmle.javascript.security.dataflow.SqlInjectionCustomizations
import advanced_security.javascript.frameworks.cap.CQL
import advanced_security.javascript.frameworks.cap.RemoteFlowSources
import advanced_security.javascript.frameworks.cap.dataflow.FlowSteps

abstract class CqlInjectionSink extends DataFlow::Node {
  /**
   * Gets the data flow node that represents the query being run, for
   * accurate reporting.
   */
  abstract DataFlow::Node getQuery();
}

/**
 * A CQL clause parameterized with a string concatentation expression.
 */
class CqlClauseWithStringConcatParameter instanceof CqlClause {
  CqlClauseWithStringConcatParameter() {
    exists(DataFlow::Node queryParameter |
      (
        if this instanceof CqlInsertClause or this instanceof CqlUpsertClause
        then
          queryParameter = this.getArgument().flow()
          or
          /*
           * Account for cases where an object with a string concatenation is passed. e.g.
           * ``` javascript
           * let insertQuery = INSERT.into`SomeEntity`.entries({col1: "column_" + col});
           * ```
           */

          queryParameter = this.getArgument().flow().(SourceNode).getAPropertyWrite().getRhs()
        else queryParameter = this.getArgument().flow()
      ) and
      exists(StringConcatenation::getAnOperand(queryParameter))
    )
  }

  Location getLocation() { result = super.getLocation() }

  string toString() { result = super.toString() }
}

/**
 * An await expression that has as its operand a CQL clause that includes a
 * string concatenation operation.
 */
class AwaitCqlClauseWithStringConcatParameter extends CqlInjectionSink {
  DataFlow::Node queryParameter;
  DataFlow::Node query;
  CqlClauseWithStringConcatParameter cqlClauseWithStringConcat;

  AwaitCqlClauseWithStringConcatParameter() {
    exists(AwaitExpr await |
      this = await.flow() and
      await.getOperand() = cqlClauseWithStringConcat.(CqlClause).asExpr()
    )
  }

  override DataFlow::Node getQuery() { result = cqlClauseWithStringConcat.(CqlClause).flow() }
}

/**
 * The first argument passed to the call to `cds.run`, `cds.db.run`, or `srv.run`
 * whose value is a CQL query object that includes a string concatenation. e.g.
 * ``` javascript
 * // 1. CQN object constructed from Fluent API
 * const query = SELECT.from`Entity1`.where("ID=" + id);
 * cds.run(query);
 *
 * // 2. CQN object parsed from a string
 * const query = cds.parse.cql("SELECT * from Entity1 where ID =" + id);
 * cds.run(query);
 *
 * // 3. An unparsed CQL string (only valid in old versions of CAP)
 * const query = "SELECT * from Entity1 where ID =" + id;
 * Service2.run(query);
 * ```
 * The `getQuery/0` member predicate gets the `query` argument of the above calls
 * to `run`.
 */
class StringConcatParameterOfCqlRunMethodQueryArgument extends CqlInjectionSink {
  CqlRunMethodCall cqlRunMethodCall;

  StringConcatParameterOfCqlRunMethodQueryArgument() {
    this = cqlRunMethodCall.getAQueryParameter()
  }

  override DataFlow::Node getQuery() { result = this }
}

/**
 * A CQL shortcut method call (`read`, `create`, ...) parameterized with a string
 * concatenation expression. e.g.
 * ``` javascript
 * cds.read("Entity1").where(`ID=${id}`); // Notice the surrounding parentheses!
 * cds.create("Entity1").entries({id: "" + id});
 * cds.update("Entity1").set("col1 = col1" + amount).where("col1 = " + id);
 * cds.insert("Entity1").entries({id: "" + id});
 * cds.upsert("Entity1").entries({id: "" + id});
 * cds.delete("Entity1").where("ID =" + id);
 * ```
 */
class CqlShortcutMethodCallWithStringConcat instanceof CqlShortcutMethodCall {
  DataFlow::Node stringConcatParameter;

  CqlShortcutMethodCallWithStringConcat() {
    stringConcatParameter = super.getAQueryParameter() and
    exists(StringConcatenation::getAnOperand(stringConcatParameter))
  }

  Location getLocation() { result = super.getLocation() }

  string toString() { result = super.toString() }

  DataFlow::Node getStringConcatParameter() { result = stringConcatParameter }
}

/**
 * A string concatenation expression included in a CQL shortcut method call. e.g.
 * ``` javascript
 * cds.read("Entity1").where(`ID=${id}`); // Notice the surrounding parentheses!
 * cds.create("Entity1").entries({id: "" + id});
 * cds.update("Entity1").set("col1 = col1" + amount).where("col1 = " + id);
 * cds.insert("Entity1").entries({id: "" + id});
 * cds.upsert("Entity1").entries({id: "" + id});
 * cds.delete("Entity1").where("ID =" + id);
 * ```
 * This class captures the string concatenation expressions appearing above:
 * 1. `ID=${id}`
 * 2. `"" + id`
 * 3. `"col1 = col1" + amount`
 * 4. `"col1 = " + id`
 * 5. `"ID =" + id`
 */
class StringConcatParameterOfCqlShortcutMethodCall extends CqlInjectionSink {
  CqlShortcutMethodCallWithStringConcat cqlShortcutMethodCallWithStringConcat;

  StringConcatParameterOfCqlShortcutMethodCall() {
    this = cqlShortcutMethodCallWithStringConcat.getStringConcatParameter()
  }

  override DataFlow::Node getQuery() { result = cqlShortcutMethodCallWithStringConcat }
}

/**
 * A CQL parser call (`cds.ql`, `cds.parse.cql`, ...) parameterized with a string
 * conatenation expression.
 */
class CqlClauseParserCallWithStringConcat instanceof CqlClauseParserCall {
  CqlClauseParserCallWithStringConcat() {
    not this.getCdlString().(StringOps::Concatenation).asExpr() instanceof TemplateLiteral and
    exists(StringConcatenation::getAnOperand(this.getCdlString()))
  }

  Location getLocation() { result = super.getLocation() }

  string toString() { result = super.toString() }
}

class CqlInjectionConfiguration extends TaintTracking::Configuration {
  CqlInjectionConfiguration() { this = "CQL injection from untrusted data" }

  override predicate isSource(DataFlow::Node source) { source instanceof RemoteFlowSource }

  override predicate isSink(DataFlow::Node node) { node instanceof CqlInjectionSink }

  override predicate isSanitizer(DataFlow::Node node) { node instanceof SqlInjection::Sanitizer }

  override predicate isAdditionalTaintStep(DataFlow::Node start, DataFlow::Node end) {
    /*
     * 1. Given a call to a CQL parser, jump from the argument to the parser call itself.
     */

    exists(CqlClauseParserCall cqlParserCall |
      start = cqlParserCall.(CqlClauseParserCall).getAnArgument() and
      end = cqlParserCall
    )
    or
    /*
     * 2. Jump from a query parameter to the CQL query clause itself. e.g. Given below code:
     *
     * ``` javascript
     * await SELECT.from(Service1Entity).where("ID=" + id);
     * ```
     *
     * This step jumps from `id` in the call to `where` to the entire SELECT clause.
     */

    exists(CqlClause cqlClause |
      start = cqlClause.getArgument().flow() and
      end = cqlClause.flow()
    )
    or
    /*
     * 3. In case of INSERT and UPSERT, jump from an object write to a query parameter to the argument itself.
     * e.g. Given below code:
     *
     * ``` javascript
     * await INSERT.into(Service1Entity).entries({ id: "" + id });
     * ```
     *
     * This step jumps from `id` in the property value expression to the enclosing object `{ id: "" + id }`.
     * This in conjunction with the above step 2 will make the taint tracker jump from `id` to the entire
     * INSERT clause.
     */

    exists(CqlClause cqlClause, PropWrite propWrite |
      (cqlClause instanceof CqlInsertClause or cqlClause instanceof CqlUpsertClause) and
      cqlClause.getArgument().flow() = propWrite.getBase() and
      start = propWrite.getRhs() and
      end = propWrite.getBase()
    )
  }
}
