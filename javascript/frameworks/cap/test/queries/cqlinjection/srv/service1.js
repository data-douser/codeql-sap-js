const cds = require("@sap/cds");

module.exports = class Service1 extends cds.ApplicationService {
  init() {
    /* ========== 1. Service1 running query on the database service using `cds.run` and friends using Fluent API ========== */
    this.on("send11", async (req) => {
      const { id } = req.data;
      const query = SELECT.from`Entity1`.where("ID=" + id);
      cds.run(query);
    });

    this.on("send12", async (req) => {
      const { id } = req.data;
      cds.read("Entity1").where("ID =" + id);
    });

    this.on("send13", async (req) => {
      const { id } = req.data;
      cds.create("Entity1").entries({id: "" + id});
    });

    this.on("send14", async (req) => {
      const { id, amount } = req.data;
      cds.update("Entity1").set("col1 = col1" + amount).where("col1 = " + id);
    });

    this.on("send15", async (req) => {
      const { id } = req.data;
      cds.insert("Entity1").entries({id: "" + id});
    });

    this.on("send16", async (req) => {
      const { id } = req.data;
      cds.upsert("Entity1").entries({id: "" + id});
    });

    this.on("send17", async (req) => {
      const { id } = req.data;
      cds.delete("Entity1").where("ID =" + id);
    });

    /* ========== 2. Service1 running query on itself by `await`-ing the query ========== */
    this.on("send21", async (req) => {
      const { id } = req.data;
      const { Service1Entity } = this.entities;
      await SELECT.from(Service1Entity).where("ID=" + id);
    });

    this.on("send22", async (req) => {
      const { id } = req.data;
      const { Service1Entity } = this.entities;
      await INSERT.into(Service1Entity).entries({ id: "" + id });
    });

    this.on("send23", async (req) => {
      const { id, amount } = req.data;
      const { Service1Entity } = this.entities;
      await UPDATE.entity(Service1Entity).set(`col1 = col1 -` + amount).where("id=" + id);
    });

    this.on("send24", async (req) => {
      const { id } = req.data;
      const { Service1Entity } = this.entities;
      await UPSERT.into(Service1Entity).entries({ id: "" + id });
    });

    this.on("send25", async (req) => {
      const { id } = req.data;
      const { Service1Entity } = this.entities;
      await DELETE.from(Service1Entity).where("ID =" + id);
    });

    /* ========== 3. Service1 running query on itself using `this.run` and friends using Fluent API ========== */
    this.on("send31", async (req) => {
      const { id } = req.data;
      const query = SELECT.from`Service1Entity`.where("ID=" + id);
      this.run(query);
    });

    this.on("send32", async (req) => {
      const { id } = req.data;
      this.read(`Service1Entity`).where("ID =" + id);
    });

    this.on("send33", async (req) => {
      const { id } = req.data;
      this.create(`Service1Entity`).entries({id: "" + id});
    });

    this.on("send34", async (req) => {
      const { id, amount } = req.data;
      this.update(`Service1Entity`).set("col1 = col1" + amount).where("col1 = " + id);
    });

    this.on("send35", async (req) => {
      const { id } = req.data;
      this.insert(`Service1Entity`).entries({id: "" + id});
    });

    this.on("send36", async (req) => {
      const { id } = req.data;
      this.upsert(`Service1Entity`).entries({id: "" + id});
    });

    this.on("send37", async (req) => {
      const { id } = req.data;
      this.delete(`Service1Entity`).where("ID =" + id);
    });

    /* ========== 4. Service1 running query on Service2 using `Service2.run` and friends ========== */
    this.on("send41", async (req) => {
      const { id } = req.data;
      const { Service2 } = await cds.connect.to("Service2");
      const query = SELECT.from`Service1Entity`.where("ID=" + id);
      Service2.run(query);
    });

    this.on("send42", async (req) => {
      const { id } = req.data;
      const { Service2 } = await cds.connect.to("Service2");
      Service2.read(`Service2Entity`).where("ID =" + id);
    });

    this.on("send43", async (req) => {
      const { id } = req.data;
      const { Service2 } = await cds.connect.to("Service2");
      Service2.create(`Service2Entity`).entries({id: "" + id});
    });

    this.on("send44", async (req) => {
      const { id, amount } = req.data;
      const { Service2 } = await cds.connect.to("Service2");
      Service2.update(`Service2Entity`).set("col1 = col1" + amount).where("col1 = " + id);
    });

    this.on("send45", async (req) => {
      const { id } = req.data;
      const { Service2 } = await cds.connect.to("Service2");
      Service2.insert(`Service2Entity`).entries({id: "" + id});
    });

    this.on("send46", async (req) => {
      const { id } = req.data;
      const { Service2 } = await cds.connect.to("Service2");
      Service2.upsert(`Service2Entity`).entries({id: "" + id});
    });

    this.on("send47", async (req) => {
      const { id } = req.data;
      const { Service2 } = await cds.connect.to("Service2");
      Service2.delete(`Service2Entity`).where("ID =" + id);
    });

    /* ========== 5. Service1 running query on Service2 using CQN parsed with `cds.ql` ========== */
    this.on("send5", async (req) => {
      const { id } = req.data;
      const { Service2 } = await cds.connect.to("Service2");
      const query = cds.ql("SELECT * from Service1Entity where ID =" + id);
      Service2.run(query);
    });

    /* ========== 6. Service1 running query on the database service using CQN parsed with `cds.parse.cql` ========== */
    this.on("send6", async (req) => {
      const { id } = req.data;
      const query = cds.parse.cql(`SELECT * from Entity1 where ID =` + id);
      cds.run(query);
    });

    /* ========== 7. Service1 running query on the database service using CQN parsed with global function `CQL` ========== */
    this.on("send6", async (req) => {
      const { id } = req.data;
      const query = cds.parse.cql(`SELECT * from Entity1 where ID =` + id);
      cds.run(query);
    });

    /* ========== 8. Service1 running query on Service2 using an unparsed CDL string (only valid in old versions of CAP) ========== */
    this.on("send71", async (req) => {
      const { id } = req.data;
      const { Service2 } = await cds.connect.to("Service2");
      const query = "SELECT * from Entity1 where ID =" + id;
      Service2.run(query);
    });

    this.on("send72", async (req) => {
      const { id } = req.data;
      const { Service2 } = await cds.connect.to("Service2");
      const query = `SELECT * from Entity1 where ID =` + id;
      Service2.run(query);
    });

    /* ========== 9. Service1 running query on Service2 using `Service2.tx( tx => tx.run(...) )` and friends ========== */
    this.on("send91", async (req) => {
      const { id } = req.data;
      const { Service2 } = await cds.connect.to("Service2");
      const query = SELECT.from`Service2Entity`.where("ID=" + id);
      Service2.tx(async (tx) => {
        tx.run(query);
      });
    });

    this.on("send92", async (req) => {
      const { id } = req.data;
      const { Service2 } = await cds.connect.to("Service2");
      Service2.tx(async (tx) => {
        tx.read(`Service2Entity`).where("ID =" + id);
      });
    });

    this.on("send93", async (req) => {
      const { id } = req.data;
      const { Service2 } = await cds.connect.to("Service2");
      Service2.tx(async (tx) => {
        tx.create(`Service2Entity`).entries({id: "" + id});
      });
    });

    this.on("send94", async (req) => {
      const { id, amount } = req.data;
      const { Service2 } = await cds.connect.to("Service2");
      Service2.tx(async (tx) => {
        tx.update(`Service2Entity`).set("col1 = col1" + amount).where("col1 = " + id);
      });
    });

    this.on("send95", async (req) => {
      const { id } = req.data;
      const { Service2 } = await cds.connect.to("Service2");
      Service2.tx(async (tx) => {
        tx.insert(`Service2Entity`).entries({id: "" + id});
      });
    });

    this.on("send96", async (req) => {
      const { id } = req.data;
      const { Service2 } = await cds.connect.to("Service2");
      Service2.tx(async (tx) => {
        tx.upsert(`Service2Entity`).entries({id: "" + id});
      });
    });

    this.on("send97", async (req) => {
      const { id } = req.data;
      const { Service2 } = await cds.connect.to("Service2");
      Service2.tx(async (tx) => {
        tx.delete(`Service2Entity`).where("ID =" + id);
      });
    });

    /* ========== 10. Service1 running query on itself using `this.tx( tx => tx.run(...) )` and friends ========== */
    this.on("send101", async (req) => {
      const { id } = req.data;
      const query = SELECT.from`Service1Entity`.where("ID=" + id);
      this.tx(async (tx) => {
        tx.run(query);
      });
    });

    this.on("send102", async (req) => {
      const { id } = req.data;
      this.tx(async (tx) => {
        tx.read(`Service1Entity`).where("ID =" + id);
      });
    });

    this.on("send103", async (req) => {
      const { id } = req.data;
      this.tx(async (tx) => {
        tx.create(`Service1Entity`).entries({id: "" + id});
      });
    });

    this.on("send104", async (req) => {
      const { id, amount } = req.data;
      this.tx(async (tx) => {
        tx.update(`Service1Entity`).set("col1 = col1" + amount).where("col1 = " + id);
      });
    });

    this.on("send105", async (req) => {
      const { id } = req.data;
      this.tx(async (tx) => {
        tx.insert(`Service1Entity`).entries({id: "" + id});
      });
    });

    this.on("send106", async (req) => {
      const { id } = req.data;
      this.tx(async (tx) => {
        tx.upsert(`Service1Entity`).entries({id: "" + id});
      });
    });

    this.on("send107", async (req) => {
      const { id } = req.data;
      this.tx(async (tx) => {
        tx.delete(`Service1Entity`).where("ID =" + id);
      });
    });

    /* ========== 11. Service1 running query on the database service using `cds.tx( tx => tx.run(...) )` and friends ========== */
    this.on("send111", async (req) => {
      const { id } = req.data;
      const query = SELECT.from`Entity1`.where("ID=" + id);
      cds.tx(async (tx) => {
        tx.run(query);
      });
    });

    this.on("send112", async (req) => {
      const { id } = req.data;
      cds.tx(async (tx) => {
        tx.read(`Entity1`).where("ID =" + id);
      });
    });

    this.on("send113", async (req) => {
      const { id } = req.data;
      cds.tx(async (tx) => {
        tx.create(`Entity1`).entries({id: "" + id});
      });
    });

    this.on("send114", async (req) => {
      const { id, amount } = req.data;
      cds.tx(async (tx) => {
        tx.update(`Entity1`).set("col1 = col1" + amount).where("col1 = " + id);
      });
    });

    this.on("send115", async (req) => {
      const { id } = req.data;
      cds.tx(async (tx) => {
        tx.insert(`Entity1`).entries({id: "" + id});
      });
    });

    this.on("send116", async (req) => {
      const { id } = req.data;
      cds.tx(async (tx) => {
        tx.upsert(`Entity1`).entries({id: "" + id});
      });
    });

    this.on("send117", async (req) => {
      const { id } = req.data;
      cds.tx(async (tx) => {
        tx.delete(`Entity1`).where("ID =" + id);
      });
    });

    /* ========== 12. Service1 running query on the database service using `cds.db.tx( tx => tx.run(...) )` and friends ========== */
    this.on("send121", async (req) => {
      const { id } = req.data;
      const query = SELECT.from`Entity1`.where("ID=" + id);
      cds.db.tx(async (tx) => {
        tx.run(query);
      });
    });

    this.on("send122", async (req) => {
      const { id } = req.data;
      cds.db.tx(async (tx) => {
        tx.read(`Entity1`).where("ID =" + id);
      });
    });

    this.on("send123", async (req) => {
      const { id } = req.data;
      cds.db.tx(async (tx) => {
        tx.create(`Entity1`).entries({id: "" + id});
      });
    });

    this.on("send124", async (req) => {
      const { id, amount } = req.data;
      cds.db.tx(async (tx) => {
        tx.update(`Entity1`).set("col1 = col1" + amount).where("col1 = " + id);
      });
    });

    this.on("send125", async (req) => {
      const { id } = req.data;
      cds.db.tx(async (tx) => {
        tx.insert(`Entity1`).entries({id: "" + id});
      });
    });

    this.on("send126", async (req) => {
      const { id } = req.data;
      cds.db.tx(async (tx) => {
        tx.upsert(`Entity1`).entries({id: "" + id});
      });
    });

    this.on("send127", async (req) => {
      const { id } = req.data;
      cds.db.tx(async (tx) => {
        tx.delete(`Entity1`).where("ID =" + id);
      });
    });
  }
};
