const cds = require('@sap/cds');
const Service1 = cds.connect.to("Service1");

cds.once('bootstrap', (app) => {
    app.serve("/log-injection").from("@advanced-security/log-injection");
});

Service1.on("Received1", async (msg) => {
    const { messageToPass } = msg.data;
    Service2.send("Received2", { messageToPass });
});
