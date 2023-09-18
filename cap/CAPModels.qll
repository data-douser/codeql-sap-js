private import javascript
private import DataFlow

abstract class Service extends ValueNode { }

class ApplicationService extends Service {
  ApplicationService() {
    /* 1. Awaiting or directly getting return value of `cds.serve` */
    // either CallExpr or AwaitExpr surrounding it
    exists(MethodCallNode cdsServeCall |
      any(CdsFacade cds).flowsTo(cdsServeCall.getReceiver()) and
      cdsServeCall.getMethodName() = "serve" and
      (
        this = cdsServeCall
        or
        this = any(AwaitExpr await).getOperand().flow()
      )
    )
    or
    /* 2. From directly using the constructor: `new cds.ApplicationService` or `new cds.Service` */
    // NewExpr
    any()
    or
    /* 3. Awaiting or directly getting return value of `cds.connect.to` */
    // either CallExpr or AwaitExpr surrounding it
    any()
  }
}

/** Last argument to the service methods `srv.before`, `srv.on`, and `srv.after` */
private class RequestHandler extends FunctionNode { }

private class ErrorHandler extends RequestHandler { }

/**
 * Subclassing ApplicationService via `extends`:
 * ```js
 * class SomeService extends cds.ApplicationService
 * ```
 */
class UserDefinedApplicationService extends ApplicationService, ClassNode { }

/**
 * Subclassing ApplicationService via `cds.service.impl`:
 * ```js
 * const cds = require('@sap/cds')
 * module.exports = cds.service.impl (function() { ... }) 
 * ```
 */
class OldStyleApplicationService extends UserDefinedApplicationService, ClassNode { }

/**
 *  Parameter of a `srv.with` method call:
 * ```js
 * cds.serve('./srv/cat-service') .with ((srv) => {
 *     srv.on ('READ','Books', (req) => req.reply([...]))
 * })
 */
class WithCallParameter extends Service, ParameterNode { }

class RemoteService extends Service, ClassNode { }

class MessagingService extends Service, ClassNode { }

class DatabaseService extends Service, ClassNode { }

class SqlService extends Service, ClassNode { }

class Request extends ValueNode, ParameterNode {
  Request() {
    /*
     * 1. Parameter of request handler of `srv.on`:
     *       `srv.on ('READ','Books', (req) => req.reply([...]))`
     */

    any()
    or
    /* 2. Parameter of `srv.send` */
    any()
  }
}

/**
 * ```js
 * const cds = require('@sap/cds')
 * ```
 */
class CdsFacade extends ModuleImportNode {
  CdsFacade() { this = moduleImport("@sap/cds") }
}

predicate selectCqlBuilder(TaggedTemplateExpr tagExpr) {
  exists(Expr taggingExpr | taggingExpr = tagExpr.getTag() |
    /* 1. SELECT `Bar` where SELECT is a local variable */
    taggingExpr.(VarRef).getName() = "SELECT" or
    /* 2. SELECT `Bar` where SELECT is a global variable */
    taggingExpr.(GlobalVarAccess).getName() = "SELECT" or
    /* 3. SELECT.one `Foo` or SELECT.from `Bar` */
    taggingExpr.(DotExpr).accesses(any(VarRef var | var.getName() = "SELECT"), _) or
    selectCqlBuilder(taggingExpr.getAChildExpr())
  )
}

predicate deleteCqlBuilder(TaggedTemplateExpr tagExpr) {
  exists(Expr taggingExpr | taggingExpr = tagExpr.getTag() |
    taggingExpr.(VarRef).getName() = "DELETE" or
    taggingExpr.(GlobalVarAccess).getName() = "DELETE" or
    taggingExpr.(DotExpr).accesses(any(VarRef var | var.getName() = "DELETE"), _) or
    deleteCqlBuilder(taggingExpr.getAChildExpr())
  )
}

abstract class CqlBuilder extends ValueNode { }

class Select extends CqlBuilder {
  Select() {
    exists(TaggedTemplateExpr tagExpr | selectCqlBuilder(tagExpr) and this = tagExpr.flow())
  }
}

class Update extends CqlBuilder { }

class Insert extends CqlBuilder {
  // Name's INSERT
}

class Delete extends CqlBuilder {
  // Name's DELETE
}

class Upsert extends CqlBuilder {
  // Name's UPSERT
}
