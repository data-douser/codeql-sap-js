import javascript
import advanced_security.javascript.frameworks.ui5.Bindings
import advanced_security.javascript.frameworks.ui5.BindingStringParser as Make

string getBindingString() {
    exists(StringLiteral stringLit | stringLit.getValue().matches("{%}") | result = stringLit.getValue())
}

module BindingStringParser = Make::BindingStringParser<getBindingString/0>;

from BindingStringParser::Binding binding
select binding


