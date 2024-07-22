# SQL Injection

Parameterizing an SQL statement in an unsafe way by directly concatenating the parameter to the statement body may allow arbitrary SQL code fragments to be included to the statement, resulting in possibly destructive behavior.

## Recommendation

### Use XSJS APIs that prepares SQL statements

There are two versions of API to communicate with SAP HANA, and both APIs provide means of preparing SQL statements that not only facilitates code reuse but also protects the parameterize statement from SQL injections.

These functions take as first argument an SQL string with placeholders represented as a question mark surrounded with parentheses (`(?)`), and the rest of the arguments consist of JavaScript expressions whose values are filled into the position of the respective placeholders.

#### Using the older API (`$.db`)

If you are using the older API that belongs to `$.db`, consider replacing string concatentation with `$.db.executeQuery`. For example, the following XSJS application substitutes the value of `someParameterValue1` and `someParameterValue2` into the position of the first and second placeholder positions, respectively.

``` javascript
let query = "INSERT INTO (?) (COL1) VALUES (?)";

let dbConnection = $.db.getConnection();
dbConnection.executeQuery(query, someParameterValue1, someParameterValue2);
```

#### Using the newer API (`$.hdb`)

If you are using the newer API that belongs to `$.hdb`, consider replacing string concatentation with `$.hdb.Connection.prepareStatement` followed by `$.db.PreparedStatement.executeUpdate`. For example, the following XSJS application substitues the value of `someParameterValue1` and `someParameterValue2` into the position of the first and second placeholder positions, respectively. After preparation, the application executes the prepared statement and then commits it to the SAP HANA database.

``` javascript
let query = "INSERT INTO (?) (COL1) VALUES (?)";
let dbConnection = $.db.getConnection();
let preparedStatement = dbConnection.prepareStatement(query, someParameterValue1, someParameterValue2);
preparedStatement.executeUpdate();
dbConnection.commit();
```

## Example

Each of the following XSJS applications directly concatenates the values of two request paremeters with fragments of an SQL query and executes it.

#### Using the older API (`$.db`)

``` javascript
let someParameterValue1 = JSON.parse(requestParameters.get("someParameter1"));
let someParameterValue2 = JSON.parse(requestParameters.get("someParameter2"));
let query = "INSERT INTO " + someParameterValue1 + ".ENTITY (COL1) VALUES (" + someParameterValue2 + ")";

let dbConnection = $.db.getConnection();
let preparedStatement = dbConnection.prepareStatement(query);
preparedStatement.executeUpdate();
dbConnection.commit();
```

#### Using the newer API (`$.hdb`)

``` javascript
let someParameterValue1 = JSON.parse(requestParameters.get("someParameter1"));
let someParameterValue2 = JSON.parse(requestParameters.get("someParameter2"));
let query = "INSERT INTO " + someParameterValue1 + " (COL1) VALUES (" + someParameterValue2 + ")";

let dbConnection = $.db.getConnection();
dbConnection.executeQuery(query);
dbConnection.commit();
```

## References

* SAP: [Server-Side JavaScript Security Considerations](https://help.sap.com/docs/SAP_HANA_PLATFORM/d89d4595fae647eabc14002c0340a999/b5e65421b48c48fa87312a6023f4c414.html).
* SAP: [Server-Side JavaScript: Injection Flaws
](https://help.sap.com/docs/SAP_HANA_PLATFORM/d89d4595fae647eabc14002c0340a999/3e9a0491d2af4b908081fbbee12bc8ba.html).
* OWASP: [SQL Injection](https://owasp.org/www-community/attacks/SQL_Injection).
* Common Weakness Enumeration: [CWE-89](https://cwe.mitre.org/data/definitions/89.html).
* Common Weakness Enumeration: [CWE-943](https://cwe.mitre.org/data/definitions/943.html).
