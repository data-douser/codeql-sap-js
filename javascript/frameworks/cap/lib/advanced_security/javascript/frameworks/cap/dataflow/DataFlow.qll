/**
 * Security-related `DataFlow::Node`s or relations between two `DataFlow::Node`s.
 */

import javascript
import advanced_security.javascript.frameworks.cap.CDS

/**
 * Methods that parse source strings into a CQL expression.
 */
class ParseSink extends DataFlow::Node {
  ParseSink() {
    exists(CdsFacade cds |
      this = cds.getMember("parse").getMember(["expr", "ref", "xpr"]).getACall().getAnArgument()
    )
  }
}

class SrvRun extends MethodCallNode {
  SrvRun() {
    exists(ServiceInstance srv |
      srv = this.getReceiver() and
      this.getMethodName() = "run"
    )
  }
}

class SrvEmit extends MethodCallNode {
  SrvEmit() {
    exists(ServiceInstance srv |
      srv = this.getReceiver() and
      this.getMethodName() = "emit"
    )
  }
}

class SrvSend extends MethodCallNode {
  SrvSend() {
    exists(ServiceInstance srv |
      srv = this.getReceiver() and
      this.getMethodName() = "send"
    )
  }
}

/**
 * A communication happening between `cds.Service`s. This includes:
 * 1. Ones based on REST-style API, based on `cds.Service.send`,
 * 2. Ones based on query-style API, based on `cds.Services.run`, and
 * 3. Ones based on emitting and subscribing to asynchronous event messages.
 */
abstract class InterServiceCommunication extends MethodCallNode {
  /* TODO: Generalize UserApplicationService to include built-in services such as log and db */
  /**
   * The service that sends the request.
   */
  UserDefinedApplicationService sender;
  /**
   * The service that receives the request and handles it.
   */
  UserDefinedApplicationService recipient;
  /**
   * The handler registration that set ups the communication.
   */
  HandlerRegistration registration;
}

class RestStyleCommunication extends InterServiceCommunication {
  override UserDefinedApplicationService sender;
  override UserDefinedApplicationService recipient;
  override HandlerRegistration registration;

  RestStyleCommunication() {
    registration = slfkjsd and
    sender = registration.getReceiver().(ServiceInstance).getDefinition() and
    recipient = sdlkfjdskf
  }
}

class CrudStyleCommunication extends InterServiceCommunication {
  override UserDefinedApplicationService sender;
  override UserDefinedApplicationService recipient;
  override HandlerRegistration registration;
}

class AsyncStyleCommunication extends InterServiceCommunication {
  override UserDefinedApplicationService sender;
  override UserDefinedApplicationService recipient;
  override HandlerRegistration registration;
}
