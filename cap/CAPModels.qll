private import javascript
private import DataFlow

abstract class Service extends ValueNode { }

class ApplicationService extends Service {
  ApplicationService() {
    /* 1. Awaiting or directly getting return value of `cds.serve` */
    any()
    or
    /* 2. From directly using the constructor: `new cds.ApplicationService` */
    any()
    or
    /* 3. Awaiting or directly getting return value of `cds.connect.to` */
    any()
  }
}

/** Last argument to the service methods `srv.before`, `srv.on`, and `srv.after` */
private class RequestHandler extends FunctionNode { }

private class ErrorHandler extends RequestHandler { }

/**
 *  Subclassing ApplicationService via `extends`:
 *  ```js
 *  class SomeService extends cds.ApplicationService
 *  ```
 */
class UserDefinedApplicationService extends ApplicationService, ClassNode { }

/**
 *  Subclassing ApplicationService via `cds.service.impl`:
 * ```js
 * cds.service.impl(() => {...})
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

class Request extends ValueNode, ClassNode {
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

private ModuleImportNode isCdsInner(TypeTracker t) {
  t.start() and
  result.getPath() = "@sap/cds"
  or
  exists(TypeTracker t2 | result = isCdsInner(t2).track(t2, t))
}

predicate isCds(ModuleImportNode node) { node = isCdsInner(TypeTracker::end()) }

/**
 * ```js
 * const cds = require('@sap/cds')
 * ```
 */
class CdsFacade extends ModuleImportNode {
  CdsFacade() { isCds(this) }
}

abstract class CqlBuilder extends SourceNode { }

class Select extends CqlBuilder { }

class Update extends CqlBuilder { }

class Insert extends CqlBuilder { }

class Delete extends CqlBuilder { }

class Upsert extends CqlBuilder { }
