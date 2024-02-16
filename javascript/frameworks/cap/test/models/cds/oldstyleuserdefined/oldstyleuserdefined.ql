import javascript
import advanced_security.javascript.frameworks.cap.CDS

from MethodCallNode cdsServiceImplCall
where exists(TUserDefinedApplicationService svc | svc = TImplMethodCall(cdsServiceImplCall))
select cdsServiceImplCall
