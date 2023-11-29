import javascript
import DataFlow
import advanced_security.javascript.frameworks.ui5.JsonParser
import semmle.javascript.security.dataflow.DomBasedXssCustomizations
import advanced_security.javascript.frameworks.ui5.UI5View
import advanced_security.javascript.frameworks.ui5.UI5HTML

module UI5 {
  private class ResourceRootPathString extends PathString {
    SapUiCoreScriptElement coreScript;

    ResourceRootPathString() { this = coreScript.getAResourceRoot().getRoot() }

    override Folder getARootFolder() { result = coreScript.getFile().getParentContainer() }
  }

  private newtype TResourceRoot =
    MkResourceRoot(string name, string root, string source) {
      exists(
        JsonParser<getAResourceRootConfig/0>::JsonObject config,
        JsonParser<getAResourceRootConfig/0>::JsonMember configEntry, SapUiCoreScriptElement coreScript
      |
        source = coreScript.getAttributeByName("data-sap-ui-resourceroots").getValue() and
        source = config.getSource() and
        config.getAMember() = configEntry
      |
        name = configEntry.getKey() and
        root = configEntry.getValue().asString()
      )
    }

  class ResourceRoot extends TResourceRoot, MkResourceRoot {
    string getName() { this = MkResourceRoot(result, _, _) }

    string getRoot() { this = MkResourceRoot(_, result, _) }

    string getSource() { this = MkResourceRoot(_, _, result) }

    string toString() { result = this.getName() + ": " + this.getRoot() }
  }

  class ResolvedResourceRoot extends Container {
    ResourceRoot unresolvedRoot;
    ResolvedResourceRoot() {
      exists(ResourceRootPathString resourceRootPathString | unresolvedRoot.getRoot() = resourceRootPathString |
      this = resourceRootPathString.resolve(resourceRootPathString.getARootFolder()).getContainer())
    }

    string getName() {
      result = unresolvedRoot.getName()
    }

    string getSource() {
      result = unresolvedRoot.getSource()
    }

    predicate contains(File file) {
      file.getParentContainer+() = this
    }
  }

  private string getAResourceRootConfig() {
    result = any(SapUiCoreScriptElement script).getAttributeByName("data-sap-ui-resourceroots").getValue()
  }

  class SapUiCoreScriptElement extends HTML::ScriptElement {
    SapUiCoreScriptElement() {
      this.getSourcePath().matches(["%sap-ui-core.js", "%sap-ui-core-nojQuery.js"])
    }

    ResourceRoot getAResourceRoot() {
      result.getSource() = this.getAttributeByName("data-sap-ui-resourceroots").getValue()
    }

    ResolvedResourceRoot getAResolvedResourceRoot() {
      result.getSource() = this.getAttributeByName("data-sap-ui-resourceroots").getValue()
    }
  }

  /** A UI5 web application manifest associated with a bootstrapped UI5 web application. */
  class WebAppManifest extends File {
    WebApp webapp;

    WebAppManifest() {
      this.getBaseName() = "manifest.json" and
      this.getParentContainer() = webapp.getWebAppFolder()
    }

    WebApp getWebapp() { result = webapp }
  }

  /** A UI5 bootstrapped web application. */
  class WebApp extends HTML::HtmlFile {
    SapUiCoreScriptElement coreScript;

    WebApp() { coreScript.getFile() = this }

    File getAResource() { coreScript.getAResolvedResourceRoot().contains(result) }

    File getResource(string path) {
      getWebAppFolder().getAbsolutePath() + "/" + path = result.getAbsolutePath()
    }

    Folder getWebAppFolder() { result = this.getParentContainer() }

    WebAppManifest getManifest() { result.getWebapp() = this }

    /**
     * Gets the JavaScript module that serves as an entrypoint to this webapp.
     */
    File getInitialModule() {
      exists(
        string initialModuleResourcePath, string resolvedModulePath,
        ResolvedResourceRoot resourceRoot
      |
        initialModuleResourcePath = coreScript.getAttributeByName("data-sap-ui-onInit").getValue() and
        coreScript.getAResolvedResourceRoot() = resourceRoot and
        resolvedModulePath =
          initialModuleResourcePath
              .regexpReplaceAll("^module\\s*:\\s*", "")
              .replaceAll(resourceRoot.getName(), resourceRoot.getAbsolutePath()) and
        result.getAbsolutePath() = resolvedModulePath + ".js"
      )
    }

    FrameOptions getFrameOptions() {
      exists(HTML::DocumentElement doc | doc.getFile() = this |
        result.asHtmlFrameOptions() = coreScript.getAnAttribute()
      )
      or
      result.asJsFrameOptions().getFile() = this
    }

    HTML::DocumentElement getDocument() {
      result.getFile() = this
    }
  }

  /**
   * https://sapui5.hana.ondemand.com/sdk/#/api/sap.ui.loader%23methods/sap.ui.loader.config
   */
  class Loader extends CallNode {
    Loader() { this = globalVarRef("sap").getAPropertyRead("ui").getAMethodCall("loader") }
  }

  /**
   * A user-defined module through `sap.ui.define` or `jQuery.sap.declare`.
   */
  abstract class UserModule extends InvokeNode {
    abstract string getADependencyType();

    abstract string getModuleFileRelativePath();

    abstract RequiredObject getRequiredObject(string dependencyType);
  }

  /**
   * A user-defined module through `sap.ui.define`.
   * https://sapui5.hana.ondemand.com/sdk/#/api/sap.ui%23methods/sap.ui.define
   */
  class SapDefineModule extends CallNode, UserModule {
    SapDefineModule() { this = globalVarRef("sap").getAPropertyRead("ui").getAMethodCall("define") }

    override string getADependencyType() { result = this.getDependencyType(_) }

    override string getModuleFileRelativePath() { result = this.getFile().getRelativePath() }

    string getDependencyType(int i) {
      result =
        this.getArgument(0).getALocalSource().(ArrayLiteralNode).getElement(i).getStringValue()
    }

    override RequiredObject getRequiredObject(string dependencyType) {
      exists(int i |
        this.getDependencyType(i) = dependencyType and
        result = this.getArgument(1).getALocalSource().(FunctionNode).getParameter(i)
      )
    }

    WebApp getWebApp() { this.getFile() = result.getAResource() }

    SapDefineModule getExtendingDefine() {
      exists(Extension baseExtension, Extension subclassExtension, SapDefineModule subclassDefine |
        baseExtension.getDefine() = this and
        subclassDefine = subclassExtension.getDefine() and
        any(RequiredObject module_ |
          module_ = subclassDefine.getRequiredObject(baseExtension.getName().replaceAll(".", "/"))
        ).flowsTo(subclassExtension.getReceiver()) and
        result = subclassDefine
      )
    }
  }

  class JQuerySap extends DataFlow::SourceNode {
    JQuerySap() {
      exists(DataFlow::GlobalVarRefNode global |
        global.getName() = "jQuery" and
        this = global.getAPropertyRead("sap")
      )
    }
  }

  /**
   * A user-defined module through `jQuery.sap.declare`.
   */
  class JQueryDefineModule extends UserModule, DataFlow::MethodCallNode {
    JQueryDefineModule() { exists(JQuerySap jquerySap | jquerySap.flowsTo(this.getReceiver())) }

    override string getADependencyType() {
      result = this.getArgument(0).asExpr().(StringLiteral).getValue()
    }

    override string getModuleFileRelativePath() { result = this.getFile().getRelativePath() }

    /** WARNING: toString() Hack! */
    override RequiredObject getRequiredObject(string dependencyType) {
      result.toString() = dependencyType and
      this.getADependencyType() = dependencyType
    }
  }

  private RequiredObject sapControl(TypeTracker t) {
    t.start() and
    exists(UserModule d, string dependencyType |
      dependencyType = ["sap/ui/core/Control", "sap.ui.core.Control"]
    |
      d.getADependencyType() = dependencyType and
      result = d.getRequiredObject(dependencyType)
    )
    or
    exists(TypeTracker t2 | result = sapControl(t2).track(t2, t))
  }

  private SourceNode sapControl() { result = sapControl(TypeTracker::end()) }

  private SourceNode sapController(TypeTracker t) {
    t.start() and
    exists(UserModule d, string dependencyType |
      dependencyType = ["sap/ui/core/mvc/Controller", "sap.ui.core.mvc.Controller"]
    |
      d.getADependencyType() = dependencyType and
      result = d.getRequiredObject(dependencyType)
    )
    or
    exists(TypeTracker t2 | result = sapController(t2).track(t2, t))
  }

  private SourceNode sapController() { result = sapController(TypeTracker::end()) }

  class CustomControl extends Extension {
    CustomControl() {
      this.getReceiver().getALocalSource() = sapControl() or
      this.getDefine() = any(SapDefineModule sapModule).getExtendingDefine()
    }

    MethodCallNode getOwnerComponentRef() {
      exists(ThisNode controlThis |
        controlThis.getBinder() = this.getAMethod() and
        controlThis.flowsTo(result.getReceiver()) and
        result.getMethodName() = "getOwnerComponent"
      )
    }
  }

  class CustomController extends Extension {
    string name;

    CustomController() {
      this.getReceiver().getALocalSource() = sapController() and
      name = this.getFile().getBaseName().regexpCapture("([a-zA-Z0-9]+).controller.js", 1)
    }

    Component getOwnerComponent() {
      /*
       * SKETCH
       * The result is the owner component of this controller if:
       * - The controller's name sans the ID prefix can be found in the manifest.json's routing target
       * - where the manifest.json is the result's ManifestJson
       */

      exists(ManifestJson manifestJson, JsonObject rootObj |
        manifestJson = result.getManifestJson()
      |
        rootObj
            .getPropValue("targets")
            .(JsonObject)
            // The individual targets
            .getPropValue(_)
            .(JsonObject)
            // The target's "viewName" property
            .getPropValue("viewName")
            .(JsonString)
            .getValue() = name
      )
    }

    MethodCallNode getOwnerComponentRef() {
      exists(ThisNode controlThis |
        controlThis.getBinder() = this.getAMethod() and
        controlThis.flowsTo(result.getReceiver()) and
        result.getMethodName() = "getOwnerComponent"
      )
    }

    /**
     * Gets a reference to a view object that can be accessed from one of the methods of this controller.
     */
    MethodCallNode getAViewReference() {
      result.getCalleeName() = "getView" and
      exists(ThisNode controllerThis |
        result.(MethodCallNode).getReceiver() = controllerThis.getALocalUse() and
        controllerThis.getBinder() = this.getAMethod()
      )
    }

    UI5View getView() { this = result.getController() }

    MethodCallNode getAnElementReference() {
      exists(MethodCallNode viewRef |
        viewRef = this.getAViewReference() and
        /* There is a view */
        viewRef.flowsTo(result.(MethodCallNode).getReceiver()) and
        /* The result is a member of this view */
        result.(MethodCallNode).getMethodName() = "byId"
      )
    }

    ThisNode getAThisNode() { result.getBinder() = this.getAMethod() }

    UI5Model getModel() {
      exists(MethodCallNode setModelCall |
        this.getAViewReference().flowsTo(setModelCall.getReceiver()) and
        setModelCall.getMethodName() = "setModel" and
        result.flowsTo(setModelCall.getAnArgument())
      )
    }

    MethodCallNode getAModelReference() {
      result.getMethodName() = "getModel" and
      this.getAViewReference().flowsTo(result.getReceiver())
    }
  }

  abstract class UI5Model extends InvokeNode {
    CustomController getController() { result.asExpr() = this.asExpr().getParent+() }
  }

  /**
   * Represents models that are loaded from an internal source, i.e. XML Models or JSON models
   * whose contents are hardcoded in a JS file or loaded from a JSON file.
   */
  abstract class UI5InternalModel extends UI5Model {
    abstract string getPathString();

    abstract string getPathString(Property property);
  }

  /** Represents models that are loaded from an external source, e.g. OData service. */
  abstract class UI5ExternalModel extends UI5Model {
    abstract string getName();
  }

  /** Model which gains content from an SAP OData service. */
  class ODataServiceModel extends UI5ExternalModel {
    string modelName;

    ODataServiceModel() {
      /*
       * SKETCH
       * This is an argument to a `this.setModel` call if:
       * - this flows from a DF node corresponding to the parent component's model
       * - and the the component's manifest.json declares the DataSource as being of OData type
       */

      /*
       * e.g. this.getView().setModel(this.getOwnerComponent().getModel("booking_nobatch"))
       */

      exists(MethodCallNode setModelCall, CustomController controller |
        /*
         * 1. This flows from a DF node corresponding to the parent component's model to the `this.setModel` call
         * i.e. Aims to capture something like `this.getOwnerComponent().getModel("someModelName")` as in
         * `this.getView().setModel(this.getOwnerComponent().getModel("someModelName"))`
         */

        modelName = this.getArgument(0).getALocalSource().asExpr().(StringLiteral).getValue() and
        this.getCalleeName() = "getModel" and
        controller.getOwnerComponentRef().flowsTo(this.(MethodCallNode).getReceiver()) and
        this.flowsTo(setModelCall.getArgument(0)) and
        setModelCall.getMethodName() = "setModel" and
        setModelCall.getReceiver() = controller.getAViewReference() and
        /* 2. The component's manifest.json declares the DataSource as being of OData type */
        controller.getOwnerComponent().getExternalModelDef(modelName).getDataSource() instanceof
          ODataDataSourceDefinition
      )
    }

    override string getName() { result = modelName }
  }

  private SourceNode sapComponent(TypeTracker t) {
    t.start() and
    exists(UserModule d, string dependencyType |
      dependencyType =
        [
          "sap/ui/core/mvc/Component", "sap.ui.core.mvc.Component", "sap/ui/core/UIComponent",
          "sap.ui.core.UIComponent"
        ]
    |
      d.getADependencyType() = dependencyType and
      result = d.getRequiredObject(dependencyType)
    )
    or
    exists(TypeTracker t2 | result = sapComponent(t2).track(t2, t))
  }

  private SourceNode sapComponent() { result = sapComponent(TypeTracker::end()) }

  import ManifestJson

  /** A UI5 Component that may contain other controllers or controls. */
  class Component extends Extension {
    Component() { this.getReceiver().getALocalSource() = sapComponent() }

    string getId() { result = this.getName().regexpCapture("([a-zA-Z0-9.]+).Component", 1) }

    ManifestJson getManifestJson() {
      /*
       * SKETCH
       * the result is a manifest.json file of this component if:
       * - this component states its manifest as string "json"
       * - this component's ID equals to that of the manifest.json's ID.
       */

      this.getMetadata().getAPropertySource("manifest").asExpr().(StringLiteral).getValue() = "json" and
      result.getId() = this.getId()
    }

    /** Get a definition of this component's model whose data source is remote. */
    DataSourceDefinition getADataSource() { result = this.getADataSource(_) }

    /** Get a definition of this component's model whose data source is remote and is called modelName. */
    DataSourceDefinition getADataSource(string modelName) { result.getName() = modelName }

    /** Get a reference to this component's external model. */
    MethodCallNode getAnExternalModelRef() { result = this.getAnExternalModelRef(_) }

    /** Get a reference to this component's external model called `modelName`. */
    MethodCallNode getAnExternalModelRef(string modelName) {
      result.getMethodName() = "getModel" and
      result.getArgument(0).asExpr().(StringLiteral).getValue() = modelName and
      exists(ExternalModelDefinition externModelDef | externModelDef.getName() = modelName)
    }

    ExternalModelDefinition getExternalModelDef(string modelName) {
      result.getFile() = this.getManifestJson() and result.getName() = modelName
    }

    ExternalModelDefinition getAnExternalModelDef() { result = this.getExternalModelDef(_) }
  }

  module ManifestJson {
    class DataSourceDefinition extends JsonObject {
      string dataSourceName;
      ManifestJson manifestJson;

      DataSourceDefinition() {
        /*
         * SKETCH
         * this is a DataSource if:
         * - its file is a ManifestJson,
         * - and it's one of the keys that the `dataSources` object has.
         */

        exists(JsonObject rootObj |
          this.getJsonFile() = manifestJson and
          rootObj.getJsonFile() = manifestJson and
          this =
            rootObj
                .getPropValue("sap.app")
                .(JsonObject)
                .getPropValue("dataSources")
                .(JsonObject)
                .getPropValue(dataSourceName)
        )
      }

      string getName() { result = dataSourceName }

      ManifestJson getManifestJson() { result = manifestJson }

      string getType() { result = this.getPropValue("type").(JsonString).getValue() }
    }

    class ODataDataSourceDefinition extends DataSourceDefinition {
      ODataDataSourceDefinition() { this.getType() = "OData" }
    }

    class JsonDataSourceDefinition extends DataSourceDefinition {
      JsonDataSourceDefinition() { this.getType() = "JSON" }
    }

    abstract class ModelDefinition extends JsonObject { }

    class InternalModelDefinition extends ModelDefinition {
      string modelName;

      InternalModelDefinition() {
        exists(JsonObject models, JsonObject modelsParent |
          models = modelsParent.getPropValue("models") and
          this = models.getPropValue(modelName) and
          this.getPropStringValue("type") =
            [
              "sap.ui.model.json.JSONModel", // A JSON Model
              "sap.ui.model.xml.XMLModel", // An XML Model
              "sap.ui.model.resource.ResourceModel" // A Resource Model, typically for i18n
            ]
        )
      }
    }

    /**
     * The definition of an external model in the `manifest.json`, in the `"models"` property.
     */
    class ExternalModelDefinition extends ModelDefinition {
      string modelName;
      string dataSourceName;

      ExternalModelDefinition() {
        exists(JsonObject models |
          this = models.getPropValue(modelName) and
          dataSourceName = this.getPropStringValue("dataSource") and
          /* This data source can be found in the "dataSources" property */
          exists(DataSourceDefinition dataSource | dataSource.getName() = dataSourceName)
        )
      }

      string getName() { result = modelName }

      string getDataSourceName() { result = dataSourceName }

      DataSourceDefinition getDataSource() { result.getName() = dataSourceName }
    }

    class ManifestJson extends File {
      string id;

      string getId() { result = id }

      ManifestJson() {
        /*
         * SKETCH
         * This is a manifest.json file if:
         * - it has at least one of the following keys:
         *  - "sap.app"
         *  - "sap.ui"
         *  - "sap.ui5"
         *  - "sap.platform.abap"
         *  - "sap.platform.hcp"
         *  - "sap.fiori"
         *  - "sap.card"
         *  - "_version"
         * - and it is a json file,
         * - and its ID is at sap.app/id.
         */

        exists(JsonObject rootObj |
          rootObj.getJsonFile() = this and
          exists(string propertyName | exists(rootObj.getPropValue(propertyName)) |
            propertyName =
              [
                "sap.app", "sap.ui", "sap.ui5", "sap.platform.abap", "sap.platform.hcp",
                "sap.fiori", "sap.card", "_version"
              ] and
            id =
              rootObj
                  .getPropValue("sap.app")
                  .(JsonObject)
                  .getPropValue("id")
                  .(JsonString)
                  .getValue()
          )
        ) and
        /* The name is fixed to "manifest.json": https://sapui5.hana.ondemand.com/sdk/#/topic/be0cf40f61184b358b5faedaec98b2da.html */
        this.getBaseName() = "manifest.json"
      }

      DataSourceDefinition getDataSource() { this = result.getManifestJson() }
    }
  }

  /** The manifest.json file serving as the app descriptor. */
  private string constructPathStringInner(Expr object) {
    if not object instanceof ObjectExpr
    then result = ""
    else
      exists(Property property | property = object.(ObjectExpr).getAProperty().(ValueProperty) |
        result = "/" + property.getName() + constructPathStringInner(property.getInit())
      )
  }

  /**
   * Create all recursive path strings of an object literal, e.g.
   * if `object = { p1: { p2: 1 }, p3: 2 }`, then create:
   * - `p1/p2`, and
   * - `p3/`.
   */
  private string constructPathString(DataFlow::ObjectLiteralNode object) {
    result = constructPathStringInner(object.asExpr())
  }

  /** Holds if the `property` is in any way nested inside the `object`. */
  private predicate propertyNestedInObject(ObjectExpr object, Property property) {
    exists(Property property2 | property2 = object.getAProperty() |
      property = property2 or
      propertyNestedInObject(property2.getInit().(ObjectExpr), property)
    )
  }

  private string constructPathStringInner(Expr object, Property property) {
    if not object instanceof ObjectExpr
    then result = ""
    else
      exists(Property property2 | property2 = object.(ObjectExpr).getAProperty().(ValueProperty) |
        if property = property2
        then result = "/" + property2.getName()
        else (
          /* We're sure this property is inside this object */
          propertyNestedInObject(property2.getInit().(ObjectExpr), property) and
          result =
            "/" + property2.getName() + constructPathStringInner(property2.getInit(), property)
        )
      )
  }

  /**
   * Create all possible path strings of an object literal up to a certain property, e.g.
   * if `object = { p1: { p2: 1 }, p3: 2 }` and `property = {p3: 2}` then create `"p3/"`.
   */
  string constructPathString(DataFlow::ObjectLiteralNode object, Property property) {
    result = constructPathStringInner(object.asExpr(), property)
  }

  /**
   * Create all recursive path strings of a JSON object, e.g.
   * if `object = { "p1": { "p2": 1 }, "p3": 2 }`, then create:
   * - `/p1/p2`, and
   * - `/p3`.
   */
  string constructPathStringJson(JsonValue object) {
    if not object instanceof JsonObject
    then result = ""
    else
      exists(string property |
        result = "/" + property + constructPathStringJson(object.getPropValue(property))
      )
  }

  /**
   * Create all possible path strings of a JSON object up to a certain property name, e.g.
   * if `object = { "p1": { "p2": 1 }, "p3": 2 }` and `propName = "p3"` then create `"/p3"`.
   * PRECONDITION: All of `object`'s keys are unique.
   */
  bindingset[propName]
  string constructPathStringJson(JsonValue object, string propName) {
    exists(string pathString | pathString = constructPathStringJson(object) |
      pathString.regexpMatch(propName) and
      result = pathString
    )
  }

  /**
   *  When given a constructor call `new JSONModel("controller/model.json")`,
   *  get the content of the file referred to by URI (`"controller/model.json"`)
   *  inside the string argument.
   */
  bindingset[path]
  JsonObject resolveDirectPath(string path) {
    exists(WebApp webApp | result.getJsonFile() = webApp.getResource(path))
  }

  /**
   *  When given a constructor call `new JSONModel(sap.ui.require.toUrl("sap/ui/demo/mock/products.json")`,
   *  get the content of the file referred to by resolving the argument.
   *  Currently only supports `sap.ui.require.toUrl`.
   */
  bindingset[path]
  JsonObject resolveIndirectPath(string path) {
    result = any(JsonObject tODO | tODO.getFile().getAbsolutePath() = path)
  }

  class JsonModel extends UI5InternalModel {
    JsonModel() {
      this instanceof NewNode and
      exists(RequiredObject jsonModel |
        jsonModel.flowsTo(this.getCalleeNode()) and
        jsonModel.getDependencyType() = "sap/ui/model/json/JSONModel"
      )
    }

    override string getPathString() {
      /* 1. new JSONModel("controller/model.json") */
      if this.getAnArgument().asExpr() instanceof StringLiteral
      then
        result =
          constructPathStringJson(resolveDirectPath(this.getAnArgument()
                  .asExpr()
                  .(StringLiteral)
                  .getValue()))
      else
        if this.getAnArgument().(MethodCallNode).getAnArgument().asExpr() instanceof StringLiteral
        then
          /* 2. new JSONModel(sap.ui.require.toUrl("sap/ui/demo/mock/products.json")) */
          result =
            constructPathStringJson(resolveIndirectPath(this.getAnArgument()
                    .(MethodCallNode)
                    .getAnArgument()
                    .asExpr()
                    .(StringLiteral)
                    .getValue()))
        else
          /*
           * 3. new JSONModel(oData) where
           *    var oData = { input: null };
           */

          exists(ObjectLiteralNode objectNode |
            objectNode.flowsTo(this.getAnArgument()) and constructPathString(objectNode) = result
          )
    }

    override string getPathString(Property property) {
      /*
       * 3. new JSONModel(oData) where
       *    var oData = { input: null };
       */

      exists(ObjectLiteralNode objectNode |
        objectNode.flowsTo(this.getAnArgument()) and
        constructPathString(objectNode, property) = result
      )
    }

    bindingset[propName]
    string getPathStringPropName(string propName) {
      exists(JsonObject jsonObject |
        jsonObject = resolveDirectPath(this.getAnArgument().asExpr().(StringLiteral).getValue())
      |
        constructPathStringJson(jsonObject, propName) = result
      )
    }

    /**
     * A model possibly supporting two-way binding explicitly set as a one-way binding model.
     */
    predicate isOneWayBinding() {
      exists(MethodCallNode call, BindingMode bindingMode |
        this.flowsTo(call.getReceiver()) and
        call.getMethodName() = "setDefaultBindingMode" and
        bindingMode.getOneWay().flowsTo(call.getArgument(0))
      )
    }
  }

  class XmlModel extends UI5InternalModel {
    XmlModel() {
      this instanceof NewNode and
      exists(RequiredObject xmlModel |
        xmlModel.flowsTo(this.getCalleeNode()) and
        xmlModel.getDependencyType() = "sap/ui/model/xml/XMLModel"
      )
    }

    override string getPathString(Property property) { result = "WIP" }

    override string getPathString() { result = "WIP" }
  }

  class BindingMode extends RequiredObject {
    BindingMode() { this.getDependencyType() = "sap/ui/model/BindingMode" }

    PropRead getOneWay() { result = this.getAPropertyRead("OneWay") }

    PropRead getTwoWay() { result = this.getAPropertyRead("TwoWay") }

    PropRead getDefault() { result = this.getAPropertyRead("Default") }

    PropRead getOneTime() { result = this.getAPropertyRead("OneTime") }
  }

  class RequiredObject extends SourceNode {
    RequiredObject() {
      exists(string dependencyType, int i |
        any(SapDefineModule sapModule).getDependencyType(i) = dependencyType and
        this =
          any(SapDefineModule sapModule)
              .getArgument(1)
              .getALocalSource()
              .(FunctionNode)
              .getParameter(i)
      )
      or
      exists(string dependencyType |
        this.toString() = dependencyType and
        any(JQueryDefineModule jQueryModule).getADependencyType() = dependencyType
      )
    }

    UserModule getDefiningModule() { result.getArgument(1).(FunctionNode).getParameter(_) = this }

    string getDependencyType() {
      exists(string dependencyType |
        this.getDefiningModule().getRequiredObject(dependencyType) = this and
        result = this.getDefiningModule().getADependencyType()
      )
    }
  }

  /**
   * `SomeModule.extend(...)` where `SomeModule` stands for a module imported with `sap.ui.define`.
   */
  class Extension extends InvokeNode, MethodCallNode {
    Extension() {
      /* 1. The receiver object is an imported one */
      any(RequiredObject module_).flowsTo(this.getReceiver()) and
      /* 2. The method name is `extend` */
      this.(MethodCallNode).getMethodName() = "extend"
    }

    FunctionNode getAMethod() {
      result = this.getArgument(1).(ObjectLiteralNode).getAPropertySource().(FunctionNode)
    }

    string getName() { result = this.getArgument(0).asExpr().(StringLiteral).getValue() }

    ObjectLiteralNode getContent() { result = this.getArgument(1) }

    Metadata getMetadata() {
      result = this.getContent().getAPropertySource("metadata")
      or
      exists(Extension baseExtension |
        baseExtension.getDefine().getExtendingDefine() = this.getDefine() and
        result = baseExtension.getMetadata()
      )
    }

    /** Gets the `sap.ui.define` call that wraps this extension. */
    SapDefineModule getDefine() { this.getEnclosingFunction() = result.getArgument(1).asExpr() }
  }

  /**
   * The property metadata found in an Extension.
   */
  class Metadata extends ObjectLiteralNode {
    Extension extension;

    Extension getExtension() { result = extension }

    Metadata() { this = extension.getContent().getAPropertySource("metadata") }

    SourceNode getProperty(string name) {
      result =
        any(PropertyMetadata property |
          property.getParentMetadata() = this and property.getName() = name
        )
    }
  }

  class AggregationMetadata extends ObjectLiteralNode {
    string name;
    Metadata parentMetadata;

    AggregationMetadata() {
      this = parentMetadata.getAPropertySource("aggregations").getAPropertySource(name)
    }

    Metadata getParentMetadata() { result = parentMetadata }

    string getName() { result = name }

    /**
     * Gets the type of this aggregation.
     */
    string getType() {
      result = this.getAPropertySource("type").getALocalSource().asExpr().(StringLiteral).getValue()
    }
  }

  class PropertyMetadata extends ObjectLiteralNode {
    string name;
    Metadata parentMetadata;

    PropertyMetadata() {
      this = parentMetadata.getAPropertySource("properties").getAPropertySource(name)
    }

    Metadata getParentMetadata() { result = parentMetadata }

    string getName() { result = name }

    /**
     * Gets the type of this aggregation.
     */
    string getType() {
      if this.isUnrestrictedStringType()
      then result = "string"
      else
        result =
          this.getAPropertySource("type").getALocalSource().asExpr().(StringLiteral).getValue()
    }

    /**
     * Holds if this property's type is an unrestricted string not belonging to any enum.
     * This makes the property a possible avenue of a client-side XSS.
     */
    predicate isUnrestrictedStringType() {
      /* text : "string" */
      this.asExpr().(StringLiteral).getValue() = "string"
      or
      /* text: { type: "string" } */
      this.getAPropertySource("type").asExpr().(StringLiteral).getValue() = "string"
      or
      /* text: { someOther: "someOtherVal", ... } */
      not exists(this.getAPropertySource("type"))
    }

    MethodCallNode getAWrite() {
      result.getMethodName() = "setProperty" and
      result.getArgument(0).asExpr().(StringLiteral).getValue() = name and
      // TODO: in same controller
      exists(WebApp webApp |
        webApp.getAResource() = this.getFile() and webApp.getAResource() = result.getFile()
      )
    }

    MethodCallNode getARead() {
      (
        result.getMethodName() = "get" + capitalize(name)
        or
        result.getMethodName() = "getProperty" and
        result.getArgument(0).asExpr().(StringLiteral).getValue() = name
      ) and
      // TODO: in same controller
      exists(WebApp webApp |
        webApp.getAResource() = this.getFile() and webApp.getAResource() = result.getFile()
      )
    }
  }
}
