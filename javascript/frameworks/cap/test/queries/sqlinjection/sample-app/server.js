const cds = require("@sap/cds");
const Service1 = await cds.connect.to("Service1");

cds.once("bootstrap", (app) => {
    app.serve("/sql-injection").from("@advanced-security/log-injection");
});

/* Upon receiving "Received1" event emitted by Service1, make Service2 run a CQL query. */
Service1.on("Received1", async (msg) => {
    const { messageToPass } = msg.data;
    await Service2.run(SELECT.from `Service2Entity`.where(`Attribute3=${messageToPass}`));
})
