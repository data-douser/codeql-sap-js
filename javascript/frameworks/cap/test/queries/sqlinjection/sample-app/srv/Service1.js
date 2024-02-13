const cds = require("@sap/cds");

/* Emit a "Received1" event upon receiving a READ request on its entity. */
module.exports = class Service1 extends cds.ApplicationService {
    this.on("READ", "Service1Entity/Attribute1", (req) => {
        const { messageToPass } = req.data;
        await this.emit("Received1", { messageToPass });
    });
}
