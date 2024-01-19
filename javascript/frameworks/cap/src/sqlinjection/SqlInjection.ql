/**
 * @name Uncontrolled data in SQL query
 * @description Including user-supplied data in a SQL query without
 *              neutralizing special elements can make code vulnerable
 *              to SQL Injection.
 * @kind problem
 * @problem.severity error
 * @id javascript/sql-injection-custom
 * @tags security
 *       external/cwe/cwe-089
 */

import javascript
import advanced_security.javascript.frameworks.cap.CDS
import advanced_security.javascript.frameworks.cap.CQL

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
        exists(CQL::TaintedClause clause | 
            clause.getArgument() = pred.asExpr() 
            and clause.asExpr() = succ.asExpr()
        )
        or
        //less precise, any concat in the alternative sql stmt construction techniques
        exists(CQL::ParseCQLTaintedClause parse |
            parse.getAnArgument() = pred    
            and parse = succ
        )
    }
}

from SqlInjectionConfiguration sql , DataFlow::Node source, DataFlow::Node sink
where sql.hasFlow(source, sink)
select sink, "Injection vulnerability found."