# Default User is overwritten as privileged

The user whose request cannot be verified as authenticated is represented as `cds.User.default` internally. If this property is set to `cds.User.Privileged`, then a service may provide assets to some user who has no rights to access them.

## Recommendation

### Set up a development profile that uses non-production authentication

It may be tempting to overwrite the `cds.User.default` as `cds.User.Privileged`, for ease of development. However, this may slip through production undeleted since the assignment to `cds.User.default` can be hard to detect because it may take various forms; e.g. the programmer may choose to store `cds.User` to a variable `v` and access `cds.User.default` by `v.default`.

A safer and more elegant solution is to set up a development profile and opt in to use a non-production strategy such as basic, dummy, or mocked during its use. This can be done in `package.json` of the CAP application at its project root:

``` json
{
  "requires": {
    "[dev]": {
      "auth": "dummy"
    }
  }
}
```

Setting `"dummy"` as the development authentication strategy has the effect of disabling `@requires` and `@restrict` annotations of CDS definitions that provides authorization. The application during development then can be run and tested with the `--profile dev` option.

```shell
cds serve --profile dev
```

## Example

Setting `cds.User.default` to `cds.User.Privileged` may happen anywhere in the application. The following is the server.js that provides the top-level definition of a CAP application, overwriting the property with the problematic class.

``` javascript
const cds = require("@sap/cds");
const app = require("express")();

/*
 * Antipattern: `cds.User.default` is overwritten to `cds.User.Privileged`
 */
cds.User.default = cdsUser.Privileged;

cds.serve("all").in(app);
```

## References

- SAP CAPire Documentation: [cds.User.default](https://cap.cloud.sap/docs/node.js/authentication#default-user).
- SAP CAPire Documentation: [Authentication Strategies](https://cap.cloud.sap/docs/node.js/authentication#strategies).
- Common Weakness Enumeration: [CWE-862](https://cwe.mitre.org/data/definitions/862.html).
- Common Weakness Enumeration: [CWE-306](https://cwe.mitre.org/data/definitions/306.html).
