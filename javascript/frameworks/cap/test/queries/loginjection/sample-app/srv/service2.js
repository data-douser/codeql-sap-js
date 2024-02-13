const cds = require("@sap/cds");
const LOG = cds.log("logger");

module.exports = cds.service.impl(() => {
    const Service1 = cds.connect.to("Service1");
    Service1.on("Received", async (msg) => {
        const { messageToPass } = msg.data;
        LOG.info("Recevied: ", messageToPass);
    });
})
