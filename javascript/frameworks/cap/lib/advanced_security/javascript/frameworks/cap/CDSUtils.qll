import javascript
import advanced_security.javascript.frameworks.cap.CDS

/**
 * An access to the `utils` module on a CDS facade.
 */
class CdsUtilsModuleAccess extends API::Node {
  CdsUtilsModuleAccess() { exists(CdsFacade cds | this = cds.getMember("utils")) }
}

class PathConverters extends DataFlow::CallNode {
  PathConverters() {
    exists(CdsUtilsModuleAccess utils |
      utils.getMember(["decodeURI", "decodeURIComponent", "local"]).getACall() = this
    )
  }

  DataFlow::Node getPath() { this.getAnArgument() = result }
}

class PathPredicates extends DataFlow::CallNode {
  PathPredicates() {
    exists(CdsUtilsModuleAccess utils | utils.getMember(["isdir", "isfile"]).getACall() = this)
  }

  DataFlow::Node getPath() { this.getAnArgument() = result }
}

class DirectoryReaders extends DataFlow::CallNode {
  DirectoryReaders() {
    exists(CdsUtilsModuleAccess utils |
      utils.getMember(["find", "stat", "readdir"]).getACall() = this
    )
  }

  DataFlow::Node getPath() { this.getAnArgument() = result }
}

class DirectoryWriters extends DataFlow::CallNode {
  DirectoryWriters() {
    exists(CdsUtilsModuleAccess utils |
      utils.getMember(["mkdirp", "rmdir", "rimraf", "rm"]).getACall() = this
    )
  }

  DataFlow::Node getPath() { this.getAnArgument() = result }
}

class FileReaders extends DataFlow::CallNode {
  FileReaders() { exists(CdsUtilsModuleAccess utils | utils.getMember(["read"]).getACall() = this) }

  DataFlow::Node getPath() { this.getArgument(0) = result }
}

class FileWriters extends DataFlow::CallNode {
  FileWriters() {
    exists(CdsUtilsModuleAccess utils | utils.getMember(["append", "write"]).getACall() = this)
  }

  SourceNode fileReaderWriterUtils(TypeTracker t) {
    t.start() and
    result = this
    or
    exists(TypeTracker t2 | result = fileReaderWriterUtils(t2).track(t2, t))
  }

  SourceNode fileReaderWriterUtils() { result = fileReaderWriterUtils(TypeTracker::end()) }

  DataFlow::Node getData() {
    this.getNumArgument() = 1 and
    this.getArgument(0) = result
    or
    this.getNumArgument() = 2 and
    this.getArgument(1) = result
  }

  DataFlow::Node getPath() {
    fileReaderWriterUtils().getAMemberCall("to").getAnArgument() = result
    or
    this.getNumArgument() = 2 and
    this.getArgument(0) = result
  }
}

class FileReaderWriters extends DataFlow::CallNode {
  FileReaderWriters() {
    exists(CdsUtilsModuleAccess utils | utils.getMember(["copy"]).getACall() = this)
  }

  SourceNode fileReaderWriterUtils(TypeTracker t) {
    t.start() and
    result = this
    or
    exists(TypeTracker t2 | result = fileReaderWriterUtils(t2).track(t2, t))
  }

  SourceNode fileReaderWriterUtils() { result = fileReaderWriterUtils(TypeTracker::end()) }

  DataFlow::Node getPath() {
    fileReaderWriterUtils().getAMemberCall("to").getArgument(_) = result
    or
    this.getAnArgument() = result
  }
}
