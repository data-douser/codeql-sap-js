var requestBody = $.request.body;

/**
 * True positive case: Saving archive entry without validation on path
 */
function test1(requestBody) {
  var zipArchive = new $.util.Zip(requestBody.asArrayBuffer());
  var targetFolderName = "unzipped";

  for (var entryPath in zipArchive) {
    var targetFilePath = require("path").join(targetFolderName, entryPath)
    require("fs").createWriteStream(targetFilePath).write(zip[entryPath]);
  }
}

/**
 * False positive case: Saving archive entry with validation on path
 */
function test2(requestBody) {
  var zipArchive = new $.util.Zip(requestBody.asArrayBuffer());
  var targetFolderName = "unzipped";

  for (var entryPath in zipArchive) {
    var targetFilePath = require("path").join(targetFolderName, entryPath)
    if (targetFilePath.indexOf(targetFolderName) === 0) {
      require("fs").createWriteStream(targetFilePath).write(zip[entryPath]);
    }
  }
}

test1(requestBody);
test2(requestBody);
