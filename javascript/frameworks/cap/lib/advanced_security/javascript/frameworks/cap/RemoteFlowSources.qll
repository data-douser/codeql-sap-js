import javascript
import advanced_security.javascript.frameworks.cap.CDS

/**
 * Either of:
 * a parameter of a handler registered for an (exposed) service on an event. e.g.
 * ```javascript
 * this.on("SomeEvent", "SomeEntity", (req) => { ... });
 * this.before("SomeEvent", "SomeEntity", (req, next) => { ... });
 * SomeService.on("SomeEvent", "SomeEntity", (msg) => { ... });
 * SomeService.after("SomeEvent", "SomeEntity", (msg) => { ... });
 * ```
 * OR
 * a handler parameter that is not connected to a service
 * possibly due to cds compilation failure
 * or non explicit service references in source. e.g.
 * ```javascript
 * cds.serve('./test-service').with((srv) => {
 *    srv.after('READ', req => req.target.data) //req
 * })
 * ```
 */
class HandlerParameterOfExposedService extends RemoteFlowSource, HandlerParameter {
  HandlerParameterOfExposedService() {
    this.getHandler().getHandlerRegistration().getService().getDefinition().isExposed()
    or
    /* no precise service definition is known */
    not exists(this.getHandler().getHandlerRegistration().getService().getDefinition())
  }

  override string toString() { result = HandlerParameter.super.toString() }

  override string getSourceType() {
    result = "Parameter of an event handler belonging to an exposed service"
  }
}
