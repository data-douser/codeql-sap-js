import javascript
import DataFlow

module CDS {
abstract class Service extends ValueNode { }

class ApplicationService extends Service {
  ApplicationService() {
    // 1. Awaiting or directly getting return value of `cds.serve`
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
    // 2. From directly using the constructor: `new cds.ApplicationService` or `new cds.Service`
    exists(MethodCallNode cdsDotService, CdsFacade cds |
      this = cdsDotService and
      cdsDotService.getReceiver() = cds and
      cdsDotService.getMethodName() = ["Service", "ApplicationService"]
    )
    or
    // 3. Awaiting or directly getting return value of `cds.connect.to`
    // TODO: Can be AwaitExpr surrounding it
    exists(CdsFacade cds, PropRef cdsConnect |
      this.(CallNode).getCalleeName() = "to" and
      this.(CallNode).getReceiver() = cdsConnect and
      cdsConnect.getPropertyName() = "connect" and
      cdsConnect.getBase() = cds
    )
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
class UserDefinedApplicationService extends ApplicationService, ClassNode {
  UserDefinedApplicationService() {
    exists(CdsFacade cdsFacade, PropRef cdsApplicationService |
      this.getADirectSuperClass() = cdsApplicationService and
      cdsApplicationService.getBase() = cdsFacade and
      cdsApplicationService.getPropertyName() = "ApplicationService"
    )
  }
}

/**
 * Subclassing ApplicationService via `cds.service.impl`:
 * ```js
 * const cds = require('@sap/cds')
 * module.exports = cds.service.impl (function() { ... })
 * ```
 */
class OldStyleApplicationService extends UserDefinedApplicationService, MethodCallNode {
  OldStyleApplicationService() {
    exists(PropRef cdsService, CdsFacade cds |
      this.getMethodName() = "impl" and
      this.getReceiver() = cdsService and
      cdsService.getPropertyName() = "service" and
      cdsService.getBase() = cds
    )
  }
}

/**
 *  Parameter of a `srv.with` method call:
 * ```js
 * cds.serve('./srv/cat-service') .with ((srv) => {
 *     srv.on ('READ','Books', (req) => req.reply([...]))
 * })
 */
class WithCallParameter extends Service, ParameterNode {
  WithCallParameter() {
    exists(MethodCallNode withCall, MethodCallNode serveCall, CdsFacade cds |
      withCall.getArgument(0) = this and
      withCall.getMethodName() = "with" and
      withCall.getReceiver() = serveCall and
      serveCall.getMethodName() = "serve" and
      serveCall.getReceiver() = cds
    )
  }
}

class RemoteService extends Service, ClassNode { }

class MessagingService extends Service, ClassNode { }

class DatabaseService extends Service, ClassNode { }

class SqlService extends Service, ClassNode { }

/**
 * Parameter of request handler of `srv.on`:
 * ```js
 * srv.on ('READ','Books', (req) => req.reply([...]))
 * ```
 */
class Request extends ValueNode, ParameterNode {
  Request() {
    exists(MethodCallNode srvOn, Service srv, FunctionNode handler |
      srvOn.getMethodName() = "on" and
      srvOn.getReceiver() = srv and
      srvOn.getLastArgument() = handler and
      handler.getLastParameter() = this
    )
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
}