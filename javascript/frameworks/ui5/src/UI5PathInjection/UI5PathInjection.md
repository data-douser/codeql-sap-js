# Client-side path injection

UI5 applications that access files using a dynamically configured path are vulnerable to injection attacks that allow an attacker to manipulate the file location.

## Recommendation

### Make path argument independent of the user input

If possible, do not parameterize the path on a user input. Either hardcode the path string in the source, or use only strings that are created within the application.

### Keep an allow-list of safe paths

Keep a strict allow-list of safe paths to load from or send request to. Before loading a script from a location outside the application or making an API request to a location, check if the path is contained in the list of safe paths. Also, make sure that the allow-list is kept up to date.

### Check the script into the repository or use package managers

Since the URL of the script may be pointing to a web server vulnerable to being hijacked, to increase the degree of control it may be a good idea to check a stable version of the script into the repository to be locally sourced from. If it is not an option, using a trusted package manager such as `npm` is also a good idea.

## Example

### Including scripts from an untrusted domain

``` javascript
sap.ui.require([
    "sap/ui/dom/includeScript"
  ],
  function(includeScript) {
    includeScript("http://some.vulnerable.domain/some-script.js");
  }
);
```

If the vulnerable domain is outside the organization and controlled by an untrusted third party, this may result in arbitrary code execution in the user's browser.

### Using user input as a name of a file to be saved

Suppose a controller is configured to receive a response from a server as follows.

``` javascript
sap.ui.define([
   "sap/ui/core/mvc/Controller",
   "sap/ui/core/util/File"
  ],
  function(Controller, File) {
    return Controller.extend("vulnerable.controller.app", {
      onInit: function() {
        let oDataV2Model = this.getOwnerComponent().getModel("some-ODatav2-model");
        this.getView().setModel(oDataV2Model);
      },
      
      onSomeEvent: function() {
        let remoteResponse = this.getView().getModel().getProperty("someProperty");
        File.save("some-content", remoteResponse, "txt", "text/plain", "utf-8");
      }
    });
  });
```

Even if the server which updates the OData V2 model is in a trusted domain such as within the organization, the server may still contain a tainted information if the UI5 application in question is already vulnerable to some other vulnerabilities, say XSS. This may lead to the attacker being able to save a file in the victim's local filesystem with the given filename which might be used for further attacks.

## References

- [CWE-829](https://cwe.mitre.org/data/definitions/829.html): Inclusion of Functionality from Untrusted Control Sphere
- [CWE-073](https://cwe.mitre.org/data/definitions/73.html): External Control of File Name or Path
- [API Documentation of `sap.ui.core.util.File`](https://sapui5.hana.ondemand.com/sdk/#/api/sap.ui.core.util.File%23methods/sap.ui.core.util.File.save)
- [API Documentation of `sap.ui.dom.includeScript`](https://sapui5.hana.ondemand.com/sdk/#/api/module:sap/ui/dom/includeScript) and [`sap.ui.dom.includeStyleSheet`](https://sapui5.hana.ondemand.com/sdk/#/api/module:sap/ui/dom/includeStylesheet)
- [API Documentation of `jQuery.sap.includeScript`](https://sapui5.hana.ondemand.com/sdk/#/api/module:sap/ui/dom/includeScript) and [`jQuery.sap.includeStyleSheet`](https://sapui5.hana.ondemand.com/sdk/#/api/module:sap/ui/dom/includeScript)
