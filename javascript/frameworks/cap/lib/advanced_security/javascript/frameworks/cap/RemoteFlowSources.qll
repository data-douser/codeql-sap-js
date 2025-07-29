import javascript
import advanced_security.javascript.frameworks.cap.CDS

/**
 * The request parameter of a handler belonging to a service that is exposed to
 * a protocol. e.g. All parameters named `req` is captured in the below example.
 * ``` javascript
 * // srv/service1.js
 * module.exports = class Service1 extends cds.ApplicationService {
 *   this.on("SomeEvent", "SomeEntity", (req) => { ... });
 *   this.before("SomeEvent", "SomeEntity", (req, next) => { ... });
 * }
 * ```
 * ``` cds
 * // srv/service1.cds
 * service Service1 @(path: '/service-1') { ... }
 * ```
 *
 * NOTE: CDS extraction can fail for various reasons, and if so the detection
 * logic falls back on overapproximating on the parameters and assume they are
 * exposed.
 */
class HandlerParameterOfExposedService extends HandlerParameter {
  HandlerParameterOfExposedService() {
    /* 1. The CDS definition is there and we can determine it is exposed. */
    this.getHandler().getHandlerRegistration().getService().getDefinition().isExposed()
    or
    /*
     * 2. (Fallback) The CDS definition is not there, so no precise service definition
     * is known.
     */

    not exists(this.getHandler().getHandlerRegistration().getService().getDefinition())
  }

  override string toString() { result = HandlerParameter.super.toString() }

  override string getSourceType() {
    result = "Parameter of an event handler belonging to an exposed service"
  }
}
