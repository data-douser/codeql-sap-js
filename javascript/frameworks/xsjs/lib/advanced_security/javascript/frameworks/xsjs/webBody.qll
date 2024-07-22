/**
 * Classes to find uses of new $.net.http.Client() .getResponse() calls.
 * A net.http.Client is the object; its .getResponse() method is a data source.
 *
 * @ kind problem
 * @id xsjs-source
 */

import javascript
import DataFlow as DF

// Identify 'new $.net.http.Client'
class NewHTTPClient extends NewExpr {
  NewHTTPClient() {
    exists(DotExpr de1 |
      this.getAChild() = de1 and
      de1.toString() = "$.net.http.Client"
    )
  }
}

// Connect
//     new $.net.http.Client();
//
// to its use:
//     _.getResponse()
DF::SourceNode myType(DF::TypeTracker t) {
  t.start() and
  exists(NewHTTPClient nc | nc.flow().getALocalSource() = result)
  or
  exists(DF::TypeTracker t2 | result = myType(t2).track(t2, t))
}

DF::SourceNode myType() { result = myType(DF::TypeTracker::end()) }

class NetHTTPSource extends MethodCallExpr {
  NetHTTPSource() {
    exists(DF::SourceNode sn, Expr db |
      sn = myType() and
      this.getMethodName() = "getResponse" and
      db = this.getReceiver()
    )
  }
}
