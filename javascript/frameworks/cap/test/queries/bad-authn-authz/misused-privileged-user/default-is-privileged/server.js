const cds = require("@sap/cds");
const app = require("express")();

/*
 * Antipattern: `cds.User.default` is overwritten to `cds.User.Privileged`
 */
const cdsUser = cds.User;
cdsUser.default = cdsUser.Privileged;

cds.serve("all").in(app);
