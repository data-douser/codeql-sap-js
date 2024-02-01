const cds = require("@sap/cds");

let cxn = cds.parse.expr (`foo.bar > 9`)
let xpr = cds.parse.xpr (`foo.bar > 9`)
let ref = cds.parse.ref (`foo.bar`)