const cds = require("@sap/cds");
const makePrivilegedUser = require("./custom-auth.js");

class CustomPrivilegedUser1 extends cds.User {
  is() {
    return true;
  }
}

class CustomPrivilegedUser2 extends cds.User {
  is() {
    return 1 == 1;
  }
}

class CustomPrivilegedUser3 extends cds.User {
  is() {
    const variable = 1;
    return variable == variable;
  }
}

class CustomPrivilegedUser4 extends cds.User {
  is() {
    const condition = true;
    if (condition) {
      return true;
    } else {
      return true;
    }
  }
}

class CustomPrivilegedUser5 extends cds.User {
  is() {
    switch (condition) {
      case "hihi":
        return true;
      case "hoho":
        return true;
    }
  }
}

class Service1 extends cds.ApplicationService {
  init() {
    /* 1. Using the function exported by the middleware directly */
    this.on("send1", async (req) => {
      const user = makePrivilegedUser(req, {}, () => { });
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
    /* 2. Creating a cds.User.Privileged directly */
    this.on("send2", async (msg) => {
      const user1 = new cds.User.Privileged("privileged1");
      this.tx({ user1 }, (tx) =>
        tx.run(
          INSERT.into("Service2Entity").entries({
            url: req._.req.url,
            user: req.user.id,
            data: msg.data.messageToPass,
          }),
        ),
      );
    });
    /* 3. Creating a custom privileged user directly */
    this.on("send3", async (msg) => {
      const user2 = new CustomPrivilegedUser1("privileged2");
      this.tx({ user2 }, (tx) =>
        tx.run(
          INSERT.into("Service2Entity").entries({
            url: req._.req.url,
            user: req.user.id,
          }),
        ),
      );
    });
  }
}
