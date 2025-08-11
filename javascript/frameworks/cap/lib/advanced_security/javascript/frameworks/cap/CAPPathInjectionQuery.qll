/**
 * Exported functions from CAP `cds.utils`.
 * Functions described from:
 * https://www.npmjs.com/package/@sap/cds?activeTab=code
 */

import javascript
import advanced_security.javascript.frameworks.cap.CDS

/**
 * An access to the `utils` module on a CDS facade.
 */
class CdsUtilsModuleAccess extends API::Node {
  CdsUtilsModuleAccess() { exists(CdsFacade cds | this = cds.getMember("utils")) }
}

class PathConverters extends DataFlow::Node {
  PathConverters() {
    exists(CdsUtilsModuleAccess utils |
      utils.getMember(["decodeURI", "decodeURIComponent", "local"]).getACall() = this
    )
  }

  SourceNode pathConvertersUtils(TypeTracker t) {
    t.start() and
    result = this
    or
    exists(TypeTracker t2 | result = pathConvertersUtils(t2).track(t2, t))
  }

  SourceNode pathConvertersUtils() { result = pathConvertersUtils(TypeTracker::end()) }

  DataFlow::Node getPath() { pathConvertersUtils().(DataFlow::CallNode).getAnArgument() = result }
}

class PathPredicates extends DataFlow::Node {
  PathPredicates() {
    exists(CdsUtilsModuleAccess utils | utils.getMember(["isdir", "isfile"]).getACall() = this)
  }

  SourceNode pathPredicateUtils(TypeTracker t) {
    t.start() and
    result = this
    or
    exists(TypeTracker t2 | result = pathPredicateUtils(t2).track(t2, t))
  }

  SourceNode pathPredicateUtils() { result = pathPredicateUtils(TypeTracker::end()) }

  DataFlow::Node getPath() { pathPredicateUtils().(DataFlow::CallNode).getAnArgument() = result }
}

class DirectoryReaders extends DataFlow::Node {
  DirectoryReaders() {
    exists(CdsUtilsModuleAccess utils |
      utils.getMember(["find", "stat", "readdir"]).getACall() = this
    )
  }

  SourceNode directoryReaderUtils(TypeTracker t) {
    t.start() and
    result = this
    or
    exists(TypeTracker t2 | result = directoryReaderUtils(t2).track(t2, t))
  }

  SourceNode directoryReaderUtils() { result = directoryReaderUtils(TypeTracker::end()) }

  DataFlow::Node getPath() { directoryReaderUtils().(DataFlow::CallNode).getAnArgument() = result }
}

class DirectoryWriters extends DataFlow::Node {
  DirectoryWriters() {
    exists(CdsUtilsModuleAccess utils |
      utils.getMember(["mkdirp", "rmdir", "rimraf", "rm"]).getACall() = this
    )
  }

  SourceNode directoryWriterUtils(TypeTracker t) {
    t.start() and
    result = this
    or
    exists(TypeTracker t2 | result = directoryWriterUtils(t2).track(t2, t))
  }

  SourceNode directoryWriterUtils() { result = directoryWriterUtils(TypeTracker::end()) }

  DataFlow::Node getPath() { directoryWriterUtils().(DataFlow::CallNode).getAnArgument() = result }
}

class FileReaders extends DataFlow::Node {
  FileReaders() { exists(CdsUtilsModuleAccess utils | utils.getMember(["read"]).getACall() = this) }

  SourceNode fileReaderUtils(TypeTracker t) {
    t.start() and
    result = this
    or
    exists(TypeTracker t2 | result = fileReaderUtils(t2).track(t2, t))
  }

  SourceNode fileReaderUtils() { result = fileReaderUtils(TypeTracker::end()) }

  DataFlow::Node getPath() { fileReaderUtils().(DataFlow::CallNode).getArgument(0) = result }
}

class FileWriters extends DataFlow::Node {
  FileWriters() {
    exists(CdsUtilsModuleAccess utils | utils.getMember(["append", "write"]).getACall() = this)
  }

  SourceNode fileWriterUtils(TypeTracker t) {
    t.start() and
    result = this
    or
    exists(TypeTracker t2 | result = fileWriterUtils(t2).track(t2, t))
  }

  SourceNode fileWriterUtils() { result = fileWriterUtils(TypeTracker::end()) }

  DataFlow::Node getData() {
    exists(DataFlow::CallNode write |
      write = fileWriterUtils() and
      (
        write.getNumArgument() = 1 and
        write.getArgument(0) = result
        or
        write.getNumArgument() = 2 and
        write.getArgument(1) = result
      )
    )
  }

  DataFlow::Node getPath() {
    exists(DataFlow::CallNode write |
      write = fileWriterUtils() and
      (
        write.getAMemberCall("to").getAnArgument() = result
        or
        write.getNumArgument() = 2 and
        write.getArgument(0) = result
      )
    )
  }
}

class FileReaderWriters extends DataFlow::Node {
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
    exists(DataFlow::CallNode copy |
      copy = fileReaderWriterUtils() and
      (
        copy.getAMemberCall("to").getArgument(_) = result
        or
        copy.getArgument(_) = result
      )
    )
  }
}

abstract class UtilsSink extends DataFlow::Node { }

abstract class UtilsExtraFlow extends DataFlow::Node { }

/**
 * This represents the data in calls as follows:
 * ```javascript
 * await write ({foo:'bar'}) .to ('some','file.json')
 * ```
 * sinks in this example are:
 * ```javascript
 * {foo:'bar'}
 * ```
 */
class WrittenData extends UtilsSink {
  WrittenData() { exists(FileWriters fw | fw.getData() = this) }
}

/**
 * This represents the filepath in calls as follows:
 * ```javascript
 * await write ({foo:'bar'}) .to ('some','file.json')
 * ```
 * sinks in this example are:
 * ```javascript
 * 'some'
 * 'file.json'
 * ```
 */
class WrittenPath extends UtilsSink {
  WrittenPath() {
    exists(FileReaders fw | fw.getPath() = this)
    or
    exists(FileReaderWriters fw | fw.getPath() = this)
    or
    exists(FileWriters fw | fw.getPath() = this)
    or
    exists(DirectoryWriters dw | dw.getPath() = this)
    or
    exists(DirectoryReaders dr | dr.getPath() = this)
  }
}

/**
 * This represents calls where the taint flows through the call. e.g.
 * ```javascript
 * let dir = isdir ('app')
 * ```
 */
class AdditionalFlowStep extends UtilsExtraFlow {
  AdditionalFlowStep() {
    exists(PathConverters pc | pc.getPath() = this)
    or
    exists(PathPredicates pr | pr.getPath() = this)
  }

  DataFlow::CallNode getOutgoingNode() { result = this }

  DataFlow::Node getIngoingNode() { result = this.(DataFlow::CallNode).getAnArgument() }
}
