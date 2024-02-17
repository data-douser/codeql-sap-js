import javascript
import DataFlow
import advanced_security.javascript.frameworks.cap.CDL

/**
 * ```js
 * const cds = require('@sap/cds')
 * ```
 */
class CdsFacade extends API::Node {
  CdsFacade() { this = API::moduleImport("@sap/cds") }

  Node getNode() { result = this.asSource() }
}

/**
 * A call to `serve` on a CDS facade.
 */
class CdsServeCall extends MethodCallNode {
  CdsServeCall() { exists(CdsFacade cds | this = cds.getMember("serve").getACall()) }
}

/**
 * A dataflow node that represents a service.
 */
abstract class ServiceInstance extends DataFlow::Node { } // Use `DataFlow::Node` to be the most general.

/**
 * A service instance obtained by the service's name, via serving
 * defined services via `cds.serve` and awaiting its promise. e.g.
 * ```javascript
 * // Obtained through `cds.serve`
 * const { Service1, Service2 } = await cds.serve("all");
 * const Service1 = await cds.serve("service-1");
 * ```
 */
class ServiceInstanceFromCdsServe extends ServiceInstance {
  ServiceInstanceFromCdsServe() {
    exists(AwaitExpr await, CdsServeCall cdsServe |
      /* 1. Obtained using `cds.Serve` */
      (
        /* 1-1. Destructuring definition */
        this.asExpr().getFirstControlFlowNode().(VarDef).getDestructuringSource() = await
        or
        /* 1-2. Direct definition */
        this.getALocalSource().asExpr() = await
      ) and
      await.getOperand().flow() = cdsServe
    )
  }
}

/**
 * A service instance obtained by the service's name, via connecting
 * to a service already being served and awaiting its promise. e.g.
 * ```javascript
 * // Obtained through `cds.connect.to`
 * const Service1 = await cds.connect.to("service-1");
 * ```
 */
class ServiceInstanceFromCdsConnectTo extends ServiceInstance {
  ServiceInstanceFromCdsConnectTo() {
    exists(AwaitExpr await, CdsConnectTo cdsConnectTo |
      this.getALocalSource().asExpr() = await and
      await.getOperand().flow() = cdsConnectTo
    )
  }
}

/**
 * A service instance obtained by directly calling the constructor
 * of its class with a `new` keyword. e.g.
 * ```javascript
 * // A constructor call
 * const srv = new cds.ApplicationService(...);
 * const srv = new cds.Service(...);
 * ```
 */
class ServiceInstanceFromConstructor extends ServiceInstance {
  ServiceInstanceFromConstructor() { this = any(CdsApplicationService cds).getAnInstantiation() }
}

/**
 * A service instance that represents an w
 */
class ServiceInstanceFromThisNode extends ServiceInstance {
  ServiceInstanceFromThisNode() {
    exists(ThisNode thisNode | thisNode.flowsTo(this) and this != thisNode)
  }
}

/**
 * The parameter node representing the service being served, given to a
 * callback argument to the `cds.serve(...).with` call. e.g.
 * ```js
 * cds.serve('./srv/some-service').with ((srv) => {
 *   srv.on ('READ','SomeEntity', (req) => req.reply([...]))
 * })
 * ```
 * This is used to extend the given service's functionality.
 */
class ServiceInstanceFromServeWithParameter extends ParameterNode, ServiceInstance {
  ServiceInstanceFromServeWithParameter() {
    exists(MethodCallNode withCall, CdsServeCall cdsServe |
      withCall.getMethodName() = "with" and
      withCall.getReceiver() = cdsServe and
      this = withCall.getArgument(0).(FunctionNode).getParameter(0)
    )
  }
}

/**
 * A Call to `cds.connect.to` that returns a promise containing the service that is asked for by its name.
 */
private class CdsConnectTo extends MethodCallNode {
  string serviceName;

  CdsConnectTo() {
    exists(CdsFacade cds |
      this = cds.getMember("connect").getMember("to").getACall() and
      serviceName = this.getArgument(0).getALocalSource().asExpr().(StringLiteral).getValue()
    )
  }
}

/**
 * A call to `before`, `on`, or `after` on an `cds.ApplicationService`.
 * It registers an handler to be executed when an event is fired,
 * to do something with the incoming request or event as its parameter.
 */
class HandlerRegistration extends MethodCallNode {
  HandlerRegistration() {
    exists(ServiceInstance srv |
      (srv.(SourceNode).flowsTo(this.getReceiver()) or srv = this.getReceiver()) and
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
 * Its first parameter is of type `cds.Event` and handles the event in an asynchronous manner,
 * or is of type `cds.Request` and handles the event synchronously.
 */
class Handler extends FunctionNode {
  UserDefinedApplicationService srv;
  string eventName;

  Handler() {
    exists(HandlerRegistration handlerRegistration |
      this = handlerRegistration.getAnArgument() and
      eventName = handlerRegistration.getArgument(0).asExpr().(StringLiteral).getValue()
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
 * Built-in event names to use to talk to a service.
 * - Event names for [REST-style API](https://cap.cloud.sap/docs/node.js/core-services#rest-style-api)
 *   - GET
 *   - PUT
 *   - POST
 *   - PATCH
 *   - DELETE
 * - Event names for [CRUD-style API](https://cap.cloud.sap/docs/node.js/core-services#crud-style-api)
 *   - READ
 *   - CREATE
 *   - INSERT
 *   - UPSERT
 *   - UPDATE
 *   - DELETE
 */
class BuiltInEventNames extends string {
  BuiltInEventNames() {
    /* 1. REST-style API names. */
    this = ["GET", "PUT", "POST", "PATCH", "DELETE"]
    or
    /* 2. CRUD-style API names. */
    this = ["READ", "CREATE", "INSERT", "UPSERT", "UPDATE", "DELETE"]
  }

  predicate isRestStyle() { this = ["GET", "PUT", "POST", "PATCH", "DELETE"] }

  predicate isCrudStyle() { this = ["READ", "CREATE", "INSERT", "UPSERT", "UPDATE", "DELETE"] }
}

/**
 * A handler that handles errors.
 */
class ErrorHandler extends Handler {
  ErrorHandler() { this.getAnEventName() = "error" }
}

newtype TUserDefinedApplicationService =
  /**
   * Subclassing `cds.ApplicationService` via a ES6 class definition.
   * ```js
   * class SomeService extends cds.ApplicationService
   * ```
   */
  TClassDefinition(ClassNode classNode) {
    exists(CdsApplicationService cdsApplicationService |
      classNode.getASuperClassNode() = cdsApplicationService.asSource()
    )
  } or
  /**
   * Subclassing `cds.ApplicationService` via a call to `cds.service.impl`.
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

  predicate hasLocationInfo(
    string filepath, int startline, int startcolumn, int endline, int endcolumn
  ) {
    this.asClassDefinition().hasLocationInfo(filepath, startline, startcolumn, endline, endcolumn) or
    this.asImplMethodCall().hasLocationInfo(filepath, startline, startcolumn, endline, endcolumn)
  }
}

private class CdsApplicationService extends API::Node {
  CdsApplicationService() { exists(CdsFacade c | this = c.getMember("ApplicationService")) }
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
