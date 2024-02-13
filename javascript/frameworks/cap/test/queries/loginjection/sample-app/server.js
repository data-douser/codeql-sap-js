const cds = require('@sap/cds');

cds.once('bootstrap', (app) => {
  app.serve("/log-injection").from("@advanced-security/log-injection");
});
