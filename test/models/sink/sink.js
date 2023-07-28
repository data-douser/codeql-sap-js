sap.ui.require(
  [
    "sap/base/util/LoaderExtensions",
    "sap/base/assert",
    "sap/base/i18n/ResourceBundle",
    "sap/ui/dom/includeScript",
    "sap/ui/core/Patcher",
    "sap/base/Log",
    "sap/ui/dom/includeStylesheet",
    "sap/ui/core/HTML",
    "sap/base/util/Properties",
    "sap/ui/core/RenderManager",
  ],
  function (
    LoaderExtensions,
    assert,
    ResourceBundle,
    includeScript,
    Patcher,
    Log,
    includeStylesheet,
    HTML,
    Properties,
    RenderManager,
  ) {
    var value = jQuery.sap.log.Logger.fatal(code0, code1, code2);
    var value = jQuery.sap.log.Logger.error(code0, code1, code2);

    var value = jQuery.sap.log.Logger.warning(code0, code1, code2);

    var value = jQuery.sap.log.Logger.info(code0, code1, code2);

    var value = jQuery.sap.log.Logger.debug(code0, code1, code2);

    var value = jQuery.sap.log.Logger.trace(code0, code1, code2);

    var value = jQuery.sap.assert(code0, code1);

    var value = jQuery.sap.registerModulePath(code0, code1);

    var value = jQuery.sap.registerResourcePath(code0, code1);

    var value = jQuery.sap.require(code0);

    var value = jQuery.sap.includeScript(code0);

    var value = jQuery.sap.includeStyleSheet(code0);

    var value = jQuery.sap.globalEval(code0);

    var value = jQuery.sap.properties(code0);

    var value = jQuery.sap.resources(code0);

    var value = jQuery.sap.sjax(code0);

    var value = jQuery.sap.syncHead(code0);

    var value = jQuery.sap.syncGet(code0, code1);

    var value = jQuery.sap.syncPost(code0, code1);

    var value = jQuery.sap.syncGetText(code0, code1);

    var value = jQuery.sap.syncGetJSON(code0, code1);
    var value = sap.base.Log.fatal(code0, code1, code2);
    var value = sap.base.Log.error(code0, code1, code2);
    var value = sap.base.Log.warning(code0, code1, code2);
    var value = sap.base.Log.info(code0, code1, code2);
    var value = sap.base.Log.debug(code0, code1, code2);
    var value = sap.base.Log.trace(code0, code1, code2);
    var value = Log.fatal(code0, code1, code2);
    var value = Log.error(code0, code1, code2);
    var value = Log.warning(code0, code1, code2);
    var value = Log.info(code0, code1, code2);
    var value = Log.debug(code0, code1, code2);
    var value = Log.trace(code0, code1, code2);
    var value = sap.base.assert(code0, code1);
    var obj = new ResourceBundle();
    var value = obj.create(code0);
    var obj = new LoaderExtensions();
    var value = obj.registerResourcePath(code0, code1);
    var obj = new Properties();
    var value = obj.create(code0);
    var obj = new HTML();
    var value = obj.content;
    var obj = new Patcher();
    var value = obj.unsafeHtml(code0);
    var obj = new RenderManager();
    var value = obj.write(code0);
    var obj = new RenderManager();
    var value = obj.writeAttribute(code0, code1);
    var obj = new RenderManager();
    var value = obj.writeAttributeEscaped(code0);
    var obj = new RenderManager();
    var value = obj.addStyle(code0, code1);
    var obj = new RenderManager();
    var value = obj.addClass(code0);
    var obj = new RenderManager();
    var value = obj.unsafeHtml(code0);
    var obj = new includeScript();
    var value = obj.fnIncludeScript(code0);
    var obj = new includeStylesheet();
    var value = obj.fnIncludeStyleSheet(code0);
  },
);
