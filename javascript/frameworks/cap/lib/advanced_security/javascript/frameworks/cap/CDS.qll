import javascript
import DataFlow

/**
 * ```js
 * const cds = require('@sap/cds')
 * ```
 */
class CdsFacade extends API::Node {
  CdsFacade() { this = API::moduleImport("@sap/cds") }
}

/**
 * A call to `serve` on a CDS facade.
 */
class CdsServeCall extends MethodCallNode {
  CdsServeCall() { exists(CdsFacade cds | this = cds.getMember("serve").getACall()) }
}

/**
 * A service instance that are obtained by the service's name, either via:
 * - Serving defined services via cds.serve and awaiting its promise, or
 * - Connecting to a service already being served and awaiting its promise, or
 * - Simply calling a constructor with a `new` keyword.
 * e.g.
 * ```javascript
 * // Obtained through `cds.serve`
 * const { Service1, Service2 } = await cds.serve("all");
 * const Service1 = await cds.serve("service-1");
 *
 * // Obtained through `cds.connect.to`
 * const Service1 = await cds.connect.to("service-1");
 *
 * // A constructor call
 * const srv = new cds.ApplicationService(...);
 * const srv = new cds.Service(...);
 * ```
 */
class ServiceInstance extends DataFlow::Node {
  ServiceInstance() {
    exists(AwaitExpr await, CdsServeCall cdsServe |
      /* 1. Obtained using `cds.Serve` */
      (
        /*
         * 1-1. Destructuring definition, e.g.
         * ```
         * const { Service1, Service2 } = await cds.serve("all");
         * ```
         */

        this.asExpr().getFirstControlFlowNode().(VarDef).getDestructuringSource() = await
        or
        /*
         * 1-2. Direct definition, e.g.
         * ```
         * const Service1 = await cds.serve("service-1");
         * ```
         */

        this.getALocalSource().asExpr() = await
      ) and
      await.getOperand().flow() = cdsServe
    )
    or
    /* 2. Obtained using `cds.connect.to` */
    exists(AwaitExpr await, CdsConnectTo cdsConnectTo |
      this.getALocalSource().asExpr() = await and
      await.getOperand().flow() = cdsConnectTo
    )
    or
    /*
     * 3. A constructor call on the class with a `new` keyword, e.g.
     * ```
     * const srv = new cds.ApplicationService(...);
     * const srv = new cds.Service(...);
     * ```
     */

    this = any(ApplicationService cds).getAnInstantiation()
  }
}

/**
 * A Call to `cds.connect.to` that returns a promise containing the service that is asked for by its name.
 */
class CdsConnectTo extends MethodCallNode {
  string serviceName;

  CdsConnectTo() {
    exists(CdsFacade cds |
      this = cds.getMember("connect").getMember("to").getACall() and
      serviceName = this.getArgument(0).getALocalSource().asExpr().(StringLiteral).getValue()
    )
  }
}

/**
 * A call to `before`, `on`, or `after` on an `ApplicationService`.
 * It registers an handler to be executed when an event is fired,
 * to do something with the incoming request or event.
 */
class HandlerRegistration extends MethodCallNode {
  HandlerRegistration() {
    exists(ApplicationService srv |
      this.getReceiver() = srv.asSource() and
      (
        this.getMethodName() = "before" or
        this.getMethodName() = "on" or
        this.getMethodName() = "after"
      )
    )
  }

  /**
   * Get the name of the event that the handler is registered for.
   */
  string getAnEventName() {
    exists(StringLiteral stringLiteral |
      stringLiteral = this.getArgument(0).asExpr() and
      result = stringLiteral.getValue()
    )
    or
    exists(ArrayLiteralNode arrayLiteral |
      arrayLiteral = this.getArgument(0) and
      result = arrayLiteral.getAnElement().asExpr().(StringLiteral).getValue()
    )
  }

  /**
   * Get the name of the entity that the handler is registered for, if any.
   */
  string getEntityName() { result = this.getArgument(1).asExpr().(StringLiteral).getValue() }
}

/**
 * The handler that implements a service's logic to deal with the incoming request or message when a certain event is fired.
 * It is the last argument to the method calls that registers the handler: either `srv.before`, `srv.on`, or `srv.after`.
 */
abstract class Handler extends FunctionNode {
  UserDefinedApplicationService srv;
  string eventName;

  Handler() {
    this.asExpr().getEnclosingFunction() = srv.getInitFunction().asExpr() and
    exists(HandlerRegistration handlerRegistration |
      handlerRegistration.asExpr() = this.getEnclosingExpr() and
      eventName = handlerRegistration.getAnEventName()
    )
  }

  /**
   * Gets the service registering this handler.
   */
  UserDefinedApplicationService getDefiningService() { result = srv }

  /**
   * Gets a name of one of the event this handler is registered for.
   */
  string getAnEventName() { result = eventName }
}

/**
 * A handler whose parameter is of type `cds.Event`. It handles asynchronous events.
 */
class MessageHandler extends Handler { }

/**
 * A handler whose parameter is of type `cds.Request`, and might contain a second parameter for
 * passing the control to the handler registered below it. It handles synchronous requests.
 */
class RequestHandler extends Handler { }

/**
 * A handler that handles errors. (TODO)
 */
class ErrorHandler extends Handler { }

newtype TUserDefinedApplicationService =
  /**
   * Subclassing `ApplicationService` via a ES6 class definition.
   * ```js
   * class SomeService extends cds.ApplicationService
   * ```
   */
  TClassDefinition(ClassNode classNode) {
    exists(ApplicationService cdsApplicationService |
      classNode.getASuperClassNode() = cdsApplicationService.asSource()
    )
  } or
  /**
   * Subclassing `ApplicationService` via a call to `cds.service.impl`.
   * ```js
   * const cds = require('@sap/cds')
   * module.exports = cds.service.impl (function() { ... })
   * ```
   */
  TImplMethodCall(MethodCallNode cdsServiceImplCall) {
    exists(CdsFacade cds |
      cdsServiceImplCall.getReceiver() = cds.getMember("service").asSource() and
      cdsServiceImplCall.getMethodName() = "impl"
    )
  }

/**
 * A custom application service of type `cds.ApplicationService`, where parts of the business logic are implemented.
 */
class UserDefinedApplicationService extends TUserDefinedApplicationService {
  ClassNode asClassDefinition() { this = TClassDefinition(result) }

  MethodCallNode asImplMethodCall() { this = TImplMethodCall(result) }

  string toString() {
    result = this.asClassDefinition().toString() or
    result = this.asImplMethodCall().toString()
  }

  FunctionNode getInitFunction() {
    result = this.asClassDefinition().getInstanceMethod("init") or
    result = this.asImplMethodCall().getArgument(0)
  }

  HandlerRegistration getAHandlerRegistration() {
    result.getEnclosingFunction() = getInitFunction().asExpr()
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
class WithCallParameter extends RequestHandler {
  WithCallParameter() {
    exists(MethodCallNode withCall, ServiceInstance svc |
      withCall.getArgument(0) = this and
      withCall.getMethodName() = "with" and
      withCall.getReceiver() = svc
    )
  }
}

/**
 * Parameter of request handler of `_.on`:
 * ```js
 * _.on ('READ','Books', (req) => req.reply([...]))
 * ```
 */
class OnNodeParam extends ValueNode, ParameterNode {
  MethodCallNode on;

  OnNodeParam() {
    exists(FunctionNode handler |
      on.getMethodName() = "on" and
      on.getLastArgument() = handler and
      handler.getLastParameter() = this
    )
  }

  MethodCallNode getOnNode() { result = on }
}

/**
 * Parameter of request handler of `srv.on`:
 * ```js
 * this.on ('READ','Books', (req) => req.reply([...]))
 * ```
 * not sure how else to know which service is registering the handler
 */
class RequestSource extends OnNodeParam {
  RequestSource() {
    // TODO : consider  - do we need to actually ever know which service the handler is associated to?
    exists(UserDefinedApplicationService svc, FunctionNode init |
      svc.asClassDefinition().getAnInstanceMember() = init and
      init.getName() = "init" and
      this.getOnNode().getEnclosingFunction() = init.getAstNode()
    )
    or
    exists(WithCallParameter pa | this.getOnNode().getEnclosingFunction() = pa.getFunction())
  }
}

private class ApplicationService extends API::Node {
  ApplicationService() { exists(CdsFacade c | this = c.getMember("ApplicationService")) }
}

/**
 * Methods that parse source strings into a CQL expression.
 */
class ParseSink extends DataFlow::Node {
  ParseSink() {
    this =
      any(CdsFacade cds)
          .getMember("parse")
          .getMember(["expr", "ref", "xpr"])
          .getACall()
          .getAnArgument()
  }
}

/**
 * A logger obtained by a call to `log` on a CDS facade. Each logger is associated with
 * its unique name.
 */
class CdsLogger extends MethodCallNode {
  string name;

  CdsLogger() {
    this = any(CdsFacade cds).getMember("log").getACall() and
    name = this.getArgument(0).getALocalSource().asExpr().(StringLiteral).getValue()
  }
}

/**
 * Arguments of calls to `cds.log.{trace, debug, info, log, warn, error}`
 */
class CdsLogSink extends DataFlow::Node {
  CdsLogSink() {
    exists(CdsLogger log, MethodCallNode loggingMethod |
      this = loggingMethod.getAnArgument() and
      not this.asExpr() instanceof Literal and
      loggingMethod.getReceiver().getALocalSource() = log and
      loggingMethod.getMethodName() = ["trace", "debug", "info", "log", "warn", "error"]
    )
  }
}
