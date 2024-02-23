import javascript

/**
 * The "cds" section of this application's `package.json`.
 */
class CdsManifest extends JsonObject {
  CdsManifest() { exists(PackageJson parent | this = parent.getPropValue("cds")) }
}

/**
 * The "requires" section of the "cds" section.
 */
class RequiresSection extends JsonObject {
  RequiresSection() { exists(CdsManifest cdsSection | this = cdsSection.getPropValue("requires")) }
}

/**
 * The service required by this application. It should provide a name
 * by which `cds.connect().to(name)` looks up the target service.
 */
class RequiredService extends JsonObject {
  string name;

  RequiredService() { exists(RequiresSection requires | this = requires.getPropValue(name)) }

  string getName() { result = name }

  /**
   * Holds if this is a declaration of a remote service. All possible kinds of remote services can
   * be found in [this part of CAPire](https://cap.cloud.sap/docs/guides/using-services#import-api).
   */
  predicate isRemote() {
    this.getPropStringValue("kind") = ["odata", "odata-v4", "odata-v2", "rest", "sql", "sqlite"]
  }

  /**
   * Holds if this is a declaration of a local service, which must provide an
   * [implementation](https://cap.cloud.sap/docs/node.js/cds-connect#cds-requires-srv-impl) as its property.
   */
  predicate isLocal() { exists(string path | path = this.getPropStringValue("impl")) }

  File getImplementationFile() { "./" + result.getRelativePath() = this.getPropStringValue("impl") }

  /**
   * Holds if this is a declaration of a database service, which is considered remote.
   */
  predicate isDatabase() { this.getPropStringValue("kind") = ["sql", "sqlite"] }
}
