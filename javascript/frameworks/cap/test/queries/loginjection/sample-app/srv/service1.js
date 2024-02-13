const cds = require("@sap/cds");

module.exports = class Service1 extends cds.ApplicationService {
    this.on("READ", "Entity1/Attribute1", (req) => {
        const { messageToPass } = req.data;
        await this.emit("Received", { messageToPass });
    });
}
