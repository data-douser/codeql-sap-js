const cds = require("@sap/cds");
const Service1 = cds.connect.to("Service1");

cds.once("bootstrap", (app) => {
    app.serve("/sql-injection").from("@advanced-security/log-injection");
});

/*  */
Service1.on("Received1", async (msg) => {
    const { messageToPass } = msg.data;
    await Service2.run(SELECT.from `Service2Entity`.where({Attribute3: messageToPass}));
})
