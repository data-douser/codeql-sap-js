import javascript
import DataFlow

module CDS {
  // TODO: should this base type be more specific?
abstract class ServiceInstance extends DataFlow::Node { }

/**
 * Call to`cds.serve`
 */
class CdsServeCall extends ServiceInstance {
  CdsServeCall(){
    this = any(CdsFacade cds).getMember("serve").getACall()
  }
}

/**
 * call to:
 *  `new cds.ApplicationService` or `new cds.Service`
 */
class ServiceConstructor extends ServiceInstance {
  ServiceConstructor(){
    this = any(ApplicationService cds).getAnInstantiation()
  }
}

/**
 * return value of `cds.connect.to`
 */
class ConnectTo extends ServiceInstance {
  ConnectTo(){
    this = any(CdsFacade cds).getMember("connect").getMember("to").getACall()
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
class UserDefinedApplicationService extends ClassNode {
  UserDefinedApplicationService() {
    exists( ApplicationService cdsApplicationService |
      this.getASuperClassNode() = cdsApplicationService.asSource()
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
class OldStyleUserDefinedApplicationService extends MethodCallNode {
  OldStyleUserDefinedApplicationService() {
    exists(CdsFacade cds |
      this = cds.getMember("service").getMember("impl").getACall()
    )
  }
}

/**
 *  Parameter of a `srv.with` method call:
 * ```js
 * cds.serve('./srv/cat-service') .with ((srv) => {
 *     srv.on ('READ','Books', (req) => req.reply([...]))
 * })
 * ```
 * 
 * TODO expand this to capture request handlers registered inside the function
 */
class WithCallParameter extends Node {
  WithCallParameter() {
    exists(MethodCallNode withCall, ServiceInstance svc |
      withCall.getArgument(0) = this and
      withCall.getMethodName() = "with" and
      withCall.getReceiver() = svc
    )
  }
}

/**
 * Parameter of request handler of `srv.on`:
 * ```js
 * this.on ('READ','Books', (req) => req.reply([...]))
 * ```
 * **this currently only describes event handlers registered in custom service definitions**
 * not sure how else to know which service is registering the handler
 */
class RequestSource extends ValueNode, ParameterNode {
  UserDefinedApplicationService svc;
  RequestSource() {
    // TODO : consider  - do we need to actually ever know which service the handler is associated to?
    exists(MethodCallNode on, FunctionNode init, FunctionNode handler |
      svc.getAnInstanceMember() = init and
      init.getName() =  "init"
      and on.getMethodName() = "on"
      and on.getEnclosingFunction() = init.getAstNode()
      and on.getLastArgument() = handler
      and handler.getLastParameter() = this
    )
  }
  UserDefinedApplicationService getDefiningService(){
    result = svc
  }

}


class ApplicationService extends API::Node {
  ApplicationService(){
    exists(CdsFacade c | this = c.getMember("ApplicationService"))
  }
}

/**
 * ```js
 * const cds = require('@sap/cds')
 * ```
 */
class CdsFacade extends API::Node {
  CdsFacade() { this = API::moduleImport("@sap/cds") }
}
}