/* ========== 1. Obtained from db/cds.entities ========== */

const db = cds.connect.to("db");

class Service1 extends cds.ApplicationService {
  init() {
    /* 1. Resolve to advanced_security.models.test.Service1Entity1 in all definitions */
    const { Service1Entity1 } = db.entities("advanced_security.models.test");
    /* 2. Resolve to advanced_security.models.test.Service1Entity2 in all definitions */
    const { Service1Entity2 } = cds.entities("advanced_security.models.test");
  }
}

/* ========== 2. Obtained from this.entities ========== */
class Service2 extends cds.ApplicationService {
  init() {
    /* 1. Resolve to advanced_security-models.test.Service2Entity1 in service-2.cds.json */
    const { Service2Entity1 } = this.entities("advanced_security.models.test");
    /* 2. Resolve to Service2.Service2Entity2 in service-2.cds.json */
    const { Service2Entity2 } = this.entities;
    /* 3. Resolve to advanced_security-models.test.Service2Entity1 in service-2.cds.json (same as 1) */
    const s2e1 = this.entities("advanced_security.models.test").Service2Entity1;
    /* 4. Resolve to Service2.Service2Entity2 in service-2.cds.json (same as 2) */
    const s2e2 = this.entities.Service2Entity2;
  }
}

/* ========== 3. Obtained from Fluent API TaggedTemplateExpr ========== */

class Service3 extends cds.ApplicationService {
  init() {
    this.on("send1", async (req) => {
      return this.tx(
        { user: new cds.User.Privileged("privileged-user-1") },
        (tx) =>
          tx.run(
            /* 1. Resolve to Service3.Service3Entity1 in service-3.cds.json */
            SELECT.from`Service3.Service3Entity1`
              .where`Attribute1=${req.data.messageToPass}`
          )
      );
    });
    this.on("send2", async (req) => {
      return this.tx(
        { user: new cds.User.Privileged("privileged-user-1") },
        (tx) =>
          tx.run(
            /* 2. Resolve to advanced_security.models.test.Service3Entity2 in service-3.cds.json */
            SELECT.from`advanced_security.models.test.Service3Entity1`
              .where`Attribute1=${req.data.messageToPass}`
          )
      );
    });
  }
}
