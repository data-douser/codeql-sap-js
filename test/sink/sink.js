////////
// Sinks for Logging sensitive data (log-injection)
////////

////////
// Sinks for XSS Injection (code-injection)
////////

// jQuery.sap.globalEval
jQuery.sap.globalEval(code);

// sap.ui.core.HTML.content
var html = new sap.ui.core.HTML({ content: code });
// sap.ui.core.HTML#content
html.content = code;
// sap.ui.core.HTML#setContent
html.stContent(code);

// Patcher.unsafeHtml
p = new Patcher();
p.unsafeHtml(code);

// RenderManager.write
import RenderManager from "sap/ui/core/RenderManager";
var rm = new RenderManager();
rm.write(code);
// RenderManager.writeAttribute
rm.writeAttribute(code);
// RenderManager.writeAttributeEscaped
rm.writeAttributeEscaped(code);
// RenderManager.addStyle
rm.addStyle(code);
// RenderManager.addClass
rm.addClass(code);
// RenderManager.unsafeHtml
rm.unsafeHtml(code);

////////
// Sinks for HTTP requests (request-forgery)
////////