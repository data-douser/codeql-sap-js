const cds = require("@sap/cds");
const makePrivilegedUser = require("./privileged-user");

module.exports = class Service1 extends cds.ApplicationService {
  init() {
    this.on("send1", async (req) => {
      /* 2. Using the function exported by the middleware directly */
      const user = makePrivilegedUser(req, {}, () => {});
      return this.tx({ user }, (tx) =>
        tx.run(
          INSERT.into("Service1Entity").entries({
            url: req._.req.url,
            user: req.user.id,
            data: req.data.messageToPass,
          }),
        ),
      );
    });
  }
};
