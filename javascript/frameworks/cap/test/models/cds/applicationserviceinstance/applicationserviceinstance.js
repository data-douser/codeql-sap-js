const cds = require("@sap/cds");
let svc = new cds.ApplicationService ("", cds.model, options)
let svc1 = await new cds.ApplicationService ("", cds.model, options)
const svc2 = cds.connect.to ('some-service')
const svc3 = await cds.connect.to ('some-service')
const { svc5 } = cds.serve ('some-service')
const { svc4 } = await cds.serve ('some-service')
