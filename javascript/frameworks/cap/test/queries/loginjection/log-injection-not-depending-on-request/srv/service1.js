const cds = require("@sap/cds");

/* Emit a "Received1" event upon receiving a READ request on its entity. */
module.exports = class Service1 extends cds.ApplicationService {
    init() {
        this.on("send1", async (req) => { // req is not used at all
            let datetime = new Date();
            const Service2 = await cds.connect.to("service-2");
            Service2.send("send2", { messageToPass: datetime.toString() });
        });
    }
}
