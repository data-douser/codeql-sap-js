const cds = require('@sap/cds');
const Service1 = await cds.connect.to("service-1");
const Service2 = await cds.connect.to("service-2");

cds.once('bootstrap', (app) => {
    app.serve("/log-injection").from("@advanced-security/log-injection");
});

Service1.on("Received1", async (msg) => {
    const { messageToPass } = msg.data;
    await Service2.send("Received2", { messageToPass });
});
