import javascript
import semmle.javascript.security.dataflow.SqlInjectionCustomizations
import advanced_security.javascript.frameworks.cap.CQL
import advanced_security.javascript.frameworks.cap.RemoteFlowSources
import advanced_security.javascript.frameworks.cap.dataflow.FlowSteps

class CqlClauseWithStringConcatParameter instanceof CqlClause {
  CqlClauseWithStringConcatParameter() {
    exists(DataFlow::Node queryParameter |
      (
        if this instanceof CqlInsertClause or this instanceof CqlUpsertClause
        then
          queryParameter = this.getArgument().flow() or
          queryParameter = this.getArgument().flow().(SourceNode).getAPropertyWrite().getRhs()
        else queryParameter = this.getArgument().flow()
      ) and
      exists(StringConcatenation::getAnOperand(queryParameter))
    )
  }

  Location getLocation() { result = super.getLocation() }

  string toString() { result = super.toString() }
}

class CqlShortcutMethodCallWithStringConcat instanceof CqlShortcutMethodCall {
  CqlShortcutMethodCallWithStringConcat() {
    exists(StringConcatenation::getAnOperand(super.getAQueryParameter()))
  }

  Location getLocation() { result = super.getLocation() }

  string toString() { result = super.toString() }
}

class CqlClauseParserCallWithStringConcat instanceof CqlClauseParserCall {
  CqlClauseParserCallWithStringConcat() {
    exists(StringConcatenation::getAnOperand(super.getCdlString()))
  }

  Location getLocation() { result = super.getLocation() }

  string toString() { result = super.toString() }
}

class CqlInjectionConfiguration extends TaintTracking::Configuration {
  CqlInjectionConfiguration() { this = "CQL injection from untrusted data" }

  override predicate isSource(DataFlow::Node source) { source instanceof RemoteFlowSource }

  override predicate isSink(DataFlow::Node node) {
    exists(CqlRunMethodCall cqlRunMethodCall |
      node = cqlRunMethodCall.(CqlRunMethodCall).getAQueryParameter()
    )
    or
    exists(CqlShortcutMethodCallWithStringConcat queryRunnerCall |
      node = queryRunnerCall.(CqlQueryRunnerCall).getAQueryParameter()
    )
    or
    exists(AwaitExpr await, CqlClauseWithStringConcatParameter cqlClauseWithStringConcat |
      node = await.flow() and
      await.getOperand() = cqlClauseWithStringConcat.(CqlClause).asExpr()
    )
  }

  override predicate isSanitizer(DataFlow::Node node) { node instanceof SqlInjection::Sanitizer }

  override predicate isAdditionalTaintStep(DataFlow::Node start, DataFlow::Node end) {
    exists(CqlClauseParserCallWithStringConcat cqlParseCallWithStringConcat |
      start = cqlParseCallWithStringConcat.(CqlClauseParserCall).getAnArgument() and
      end = cqlParseCallWithStringConcat
    )
    or
    exists(CqlClause cqlClause |
      start = cqlClause.getArgument().flow() and
      end = cqlClause.flow()
    )
  }
}
