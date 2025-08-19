/**
 * Exported functions from CAP `cds.utils`.
 * Functions described from:
 * https://www.npmjs.com/package/@sap/cds?activeTab=code
 */

import javascript
import advanced_security.javascript.frameworks.cap.CDSUtils

abstract class UtilsAccessedPathSink extends DataFlow::Node { }

abstract class UtilsControlledDataSink extends DataFlow::Node { }

abstract class UtilsControlledPathSink extends DataFlow::Node { }

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
class WrittenData extends UtilsControlledDataSink {
  WrittenData() { exists(FileWriters fw | fw.getData() = this) }
}

/**
 * This represents the filepath accessed as an input for the data in calls as follows:
 * ```javascript
 * await copy('db/data').to('dist/db/data')
 * ```
 * sinks in this example are:
 * ```javascript
 * 'db/data'
 * ```
 */
class AccessedPath extends UtilsAccessedPathSink {
  AccessedPath() { exists(FileReaderWriters fw | fw.getFromPath() = this) }
}

/**
 * This represents the filepath where data is written or a file operation is performed in calls as follows:
 * ```javascript
 * await write ({foo:'bar'}) .to ('some','file.json')
 * ```
 * sinks in this example are:
 * ```javascript
 * 'some'
 * 'file.json'
 * ```
 */
class ControlledInputPath extends UtilsControlledPathSink {
  ControlledInputPath() {
    exists(FileReaders fw | fw.getPath() = this)
    or
    exists(FileReaderWriters fw | fw.getToPath() = this)
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
