# Zip Slip

A zip archive received from a remote location may contain arbitrary paths which, when translated to an absolute path, may escape the directory where it is extracted. Such paths may include one or more `../` to traverse the directory tree upwards to write to an arbitrary location, such as the root directory (`/`) or a sensitive path like `/usr/local/`. A sophisticated attack may also attempt to overwrite an existing file by making the filename identical as that of the target file.

## Recommendation

Validate the path of each zip entry before writing them to a file. Several different tactics may be used to prevent the path traversal by one or more of `../` occuring in a zip entry's path.

### Check if the path string contains `../`

A naive but effective way to validate the path of a zip entry is to check if its path, converted to string, contains any occurrences of `../`. If a path does have one, then it can be suspected that the creator of the zip archive is attempting a path traversal attack.

### Resolve the path and check if the target directory is its prefix 

A more sophisticated way is to use a JavaScript library function that can be used to check if a substring is a prefix of a string. For example, the following XSJS application uses `String.indexOf(substring)` to check if the name of the directory is indeed the directory resolved by `path.join(prefix, suffix)`. If the absolute path obtained by the `join` function does not start with the target folder's name, the `entryPath` contains bits such as `../` that traverses the path.

``` javascript
var zipArchive = new $.util.Zip(requestBody.asArrayBuffer());
var targetFolderName = "unzipped";

for (var entryPath in zipArchive) {
  var targetFilePath = require("path").join(targetFolderName, entryPath)
  if (targetFilePath.indexOf(targetFolderName) === 0) {
    require("fs").createWriteStream(targetFilePath).write(zip[entryPath]);
  }
}
```

### Example

This XSJS application simply appends the path of each entry to a target directory name and a separator then saves it to a file with the concatenated path, thereby skipping any validation on it.

``` javascript
var zipArchive = new $.util.Zip(requestBody.asArrayBuffer());
var targetFolderName = "unzipped";

for (var entryPath in zipArchive) {
  var targetFilePath = targetFolderName + "/" + entryPath;
  require("fs").createWriteStream(targetFilePath).write(zip[entryPath]);
}
```

## References

* SAP: [Server-Side JavaScript Security Considerations](https://help.sap.com/docs/SAP_HANA_PLATFORM/d89d4595fae647eabc14002c0340a999/b5e65421b48c48fa87312a6023f4c414.html).
* OWASP: [Path Traversal](https://owasp.org/www-community/attacks/Path_Traversal).
* SAP XSJS Documentation: [$.util.Zip](https://help.sap.com/doc/3de842783af24336b6305a3c0223a369/2.0.03/en-US/$.util.Zip.html).
* Common Weakness Enumeration: [CWE-23](https://cwe.mitre.org/data/definitions/23.html).
* Common Weakness Enumeration: [CWE-59](https://cwe.mitre.org/data/definitions/59.html).
