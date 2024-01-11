import javascript
import advanced_security.javascript.frameworks.cap.CDS
import advanced_security.javascript.frameworks.cap.CQL
import semmle.javascript.StringConcatenation

class SqlInjectionConfiguration extends TaintTracking::Configuration {
    SqlInjectionConfiguration(){
        this = ""
    }
    override predicate isSource(DataFlow::Node source) {
        exists(CDS::RequestSource src |
            source = src )
    }

    override predicate isSink(DataFlow::Node sink) { 
        exists(CQL::CQLSink snk |
            sink = snk )
    }

    override predicate isAdditionalTaintStep(DataFlow::Node pred, DataFlow::Node succ) { 
        //string concatenation in a clause arg taints the clause
        exists(CQL::CqlClause clause | 
            clause.getArgument() = pred.asExpr() 
            and clause.asExpr() = succ.asExpr()
            and
            exists(StringConcatenation::getAnOperand(pred))
        )
    }
}

from SqlInjectionConfiguration sql , DataFlow::Node source, DataFlow::Node sink
where sql.hasFlow(source, sink)
select sink, "Injection vulnerability found."