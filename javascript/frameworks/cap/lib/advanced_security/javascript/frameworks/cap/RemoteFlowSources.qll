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
/* TODO: narrow the definition down to exposed events */
class HandlerParameter extends ParameterNode, RemoteFlowSource {
  HandlerParameter() { exists(EventHandler handler | this = handler.getParameter(0)) }

  override string getSourceType() { result = "Parameter of an event handler" }
}
