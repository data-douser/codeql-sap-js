import javascript
import advanced_security.javascript.frameworks.cap.CDS

/**
 * A parameter of a handler registered for a service on an event. e.g.
 * ```javascript
 * this.on("SomeEvent", "SomeEntity", (req) => { ... });
 * this.before("SomeEvent", "SomeEntity", (req, next) => { ... }); // only `req` is captured
 * SomeService.on("SomeEvent", "SomeEntity", (msg) => { ... });
 * SomeService.after("SomeEvent", "SomeEntity", (msg) => { ... });
 * ```
 * All the parameters named `req` and `msg` are captured in the above example.
 */
class HandlerParameter extends ParameterNode, RemoteFlowSource {
  HandlerParameter() {
    exists(
      Handler handler, HandlerRegistration handlerRegistration,
      UserDefinedApplicationService service
    |
      handler = handlerRegistration.getHandler() and
      this = handler.getParameter(0) and
      service.getAHandlerRegistration() = handlerRegistration and
      service.isExposed()
    )
  }

  override string getSourceType() {
    result = "Parameter of an event handler belonging to an exposed service"
  }
}

/**
 * A service may be described only in a CDS file, but event handlers may still be registered in a format such as:
 * ```javascript
 * module.exports = srv => {
 * srv.before('CREATE', 'Media', req => { //service name is used to describe which to register this handler to
 * ```
 * parameters named `req` are captured in the above example.
 */
class ServiceinCDSHandlerParameter extends RemoteFlowSource {
  ServiceinCDSHandlerParameter() {
    exists(MethodCallNode m, CdlEntity service, string serviceName |
      service.getName().regexpReplaceAll(".*\\.", "") = serviceName and
      m.getArgument(1).toString().regexpReplaceAll("'", "") = serviceName and
      this = m.getArgument(2) and
      m.getMethodName() in ["on", "before", "after"]
    )
  }

  override string getSourceType() {
    result = "Parameter of an event handler belonging to an exposed service defined in a cds file"
  }
}
