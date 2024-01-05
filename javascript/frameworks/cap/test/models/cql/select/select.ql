import javascript
import advanced_security.javascript.frameworks.cap.CQL
import advanced_security.javascript.frameworks.cap.CDS

// from CQL::CqlSelectExpr s
// select s.getLocation(), s
from API::Node cds, PropRef cdsDotQL, Node v , VarRef var
where
cds = API::moduleImport("@sap/cds") and
      cds.getMember("ql").asSource() = cdsDotQL
      and cdsDotQL.(DataFlow::SourceNode).flowsTo+(v)
      //and var.getADeclaration().getFirstControlFlowNode() = v.getAstNode().getAChild().getFirstControlFlowNode()
      and var.getName() = "SELECT"
      and v.getAstNode().getAChild() = var
      select v, 
      v.getAstNode().getAChild(),
      //v.getAstNode().getAChild().getFirstControlFlowNode(), 
     // v.getAstNode().getAChild().getAQlClass(), 
      var, var.getVariable()//.getADeclaration().getAQlClass(), var.getADeclaration().getFirstControlFlowNode()

// from Variable v 
// where v.getName() = "SELECT"
// select v, v.getADeclaration(), v.getADeclaration().getAQlClass()