import javascript
import advanced_security.javascript.frameworks.ui5.Bindings
import advanced_security.javascript.frameworks.ui5.BindingStringParser as Make

class BindingStringReader extends StringLiteral {
  BindingStringReader() { this.getValue().matches("{%}") }

  string getBindingString() { result = this.getValue() }

  DataFlow::Node getANode() { result.asExpr() = this }
}

module BindingStringParser = Make::BindingStringParser<BindingStringReader>;

from BindingStringParser::Binding binding
select binding
