import javascript
import UI5AMDModule
import semmle.javascript.frameworks.data.internal.ApiGraphModelsExtensions

// import UI5::UI5
// from DataFlow::Configuration cfg, DataFlow::Node sink
// where cfg.isSink(sink, _)
// select sink
from string type, string path, string kind
where sinkModel(type, path, kind)
select type, path, kind
