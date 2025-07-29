const cds = require("@sap/cds");
const app = require("express")();

cds.serve("all").in(app);

cds.serve('./some-service').with((srv) => {
  srv.before('READ', 'Books', (req) => req.reply([])) // SAFE: Exposed service (fallback), but not a taint source
})