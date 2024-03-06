/**
 * Definitions pertaining to the application as a whole.
 */

import javascript
import advanced_security.javascript.frameworks.cap.PackageJson

class RootDirectory extends Folder {
  RootDirectory() {
    exists(PackageJson packageJson | this = packageJson.getJsonFile().getParentContainer())
  }

  /**
   * Gets the path of a file relative to this root directory.
   */
  string getFilePathRelativeToRoot(File file) {
    result = file.getAbsolutePath().regexpReplaceAll(this.getAbsolutePath(), ".")
  }
}
