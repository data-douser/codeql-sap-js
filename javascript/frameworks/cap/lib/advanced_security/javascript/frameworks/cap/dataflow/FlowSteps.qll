/**
 * Additional flow steps to be registered to `DataFlow::SharedFlowStep`.
 */

import javascript
import semmle.javascript.dataflow.DataFlow
import advanced_security.javascript.frameworks.cap.dataflow.DataFlow

/**
 * An issuing of and handling of a request or a message in an inter-service communication.
 */
class InterServiceCommunicationStepFromSenderToReceiver extends DataFlow::SharedFlowStep {
  override predicate step(DataFlow::Node pred, DataFlow::Node succ) {
    (
      exists(InterServiceCommunication communication, string communicationEventName |
        pred = communication.getCommunicationMethodCall().getArgument(1) and
        communicationEventName =
          communication
              .getCommunicationMethodCall()
              .getArgument(0)
              .getALocalSource()
              .asExpr()
              .(StringLiteral)
              .getValue() and
        succ =
          communication
              .getRecipient()
              .getDefinition()
              .getHandlerRegistration(communicationEventName)
              .getHandler()
              .getParameter(0)
      )
      or
      exists(InterServiceCommunication communication, string communicationEventName |
        succ = communication.getCommunicationMethodCall().getArgument(1) and
        communicationEventName =
          communication
              .getCommunicationMethodCall()
              .getArgument(0)
              .getALocalSource()
              .asExpr()
              .(StringLiteral)
              .getValue() and
        pred = any(PropWrite write | write.getBase() = succ).getRhs()
      )
    ) and
    /* Restrict search space to the same application. */
    exists(RootDirectory rootDirectory |
      rootDirectory.contains(pred.getFile()) and
      rootDirectory.contains(succ.getFile())
    )
  }
}
