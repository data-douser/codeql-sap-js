const cds = require("@sap/cds");
const LOG = cds.log("logger");

module.exports = cds.service.impl(() => {
    /* Log upon receiving an "Received2" event. */
    this.on("send2", async (msg) => {
        const { messageToPass } = msg.data;
        /* A log injection sink. */
        LOG.info("Received: ", messageToPass);  // CAP log injection alert
  });
})
