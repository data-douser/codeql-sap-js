sap.ui.require(["sap/base/util/UriParameters", "sap/ui/core/Patcher", "sap/ui/core/RenderManager", "sap/base/Log"],
    function (UriParameters, Patcher, RenderManager, Log) {
        ////////
        // Sinks for Logging sensitive data (log-injection)
        ////////

        // jQuery.sap.log.info
        jQuery.sap.log.Logger.info(code1, code2, code3);

        // jQuery.sap.log.fatal
        jQuery.sap.log.Logger.fatal(code1, code2, code3);

        // jQuery.sap.log.warning
        jQuery.sap.log.Logger.warning(code1, code2, code3);

        // jQuery.sap.log.debug
        jQuery.sap.log.Logger.debug(code1, code2, code3);

        // jQuery.sap.log.trace
        jQuery.sap.log.Logger.trace(code1, code2, code3);

        // jQuery.sap.log.error
        jQuery.sap.log.Logger.error(code1, code2, code3);

        Log.fatal(code1, code2, code3);
        Log.error(code1, code2, code3);
        Log.warning(code1, code2, code3);
        Log.info(code1, code2, code3);
        Log.debug(code1, code2, code3);
        Log.trace(code1, code2, code3);

        sap.base.Log.fatal(code1, code2, code3);
        sap.base.Log.error(code1, code2, code3);
        sap.base.Log.warning(code1, code2, code3);
        sap.base.Log.info(code1, code2, code3);
        sap.base.Log.debug(code1, code2, code3);
        sap.base.Log.trace(code1, code2, code3);

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
        html.setContent(code);

        // sap.ui.core.Patcher.unsafeHtml
        var p = new Patcher();
        p.unsafeHtml(code);

        // RenderManager.write
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

    });