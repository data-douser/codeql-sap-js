// TaggedTemplate: UPDATE, entity, set, with, where

let diff = 1;
let val = 2;

/* ========== UPDATE (entity), set ========== */

/* Without `entity` */
var update = UPDATE`Table`.set`col1 = col1 - ${diff}`;
var update = UPDATE`Table`.set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }); // CQN
var update = UPDATE`Table`.set({ col1: diff }); // QBE

/* With `entity` */
var update = UPDATE.entity(Table).set`col1 = col1 - ${diff}`;
var update = UPDATE.entity(Table).set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }); // CQN
var update = UPDATE.entity(Table).set({ col1: diff }); // QBE

var update = UPDATE.entity("Table").set`col1 = col1 - ${diff}`;
var update = UPDATE.entity("Table").set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }); // CQN
var update = UPDATE.entity("Table").set({ col1: diff }); // QBE

var update = UPDATE.entity`Table`.set`col1 = col1 - ${diff}`;
var update = UPDATE.entity`Table`.set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }); // CQN
var update = UPDATE.entity`Table`.set({ col1: diff }); // QBE

/* ========== UPDATE (entity), with ========== */

/* Without `entity` */
var update = UPDATE`Table`.with`col1 = col1 - ${diff}`;
var update = UPDATE`Table`.with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }); // CQN
var update = UPDATE`Table`.with({ col1: diff }); // QBE

/* With `entity` */
var update = UPDATE.entity`Table`.with`col1 = col1 - ${diff}`;
var update = UPDATE.entity`Table`.with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }); // CQN
var update = UPDATE.entity`Table`.with({ col1: diff }); // QBE

/* ========== UPDATE (entity), set, where ========== */

/* Without `entity` */
var update = UPDATE`Table`.set`col1 = col1 - ${diff}`.where({ col1: "*" });
var update = UPDATE`Table`.set`col1 = col1 - ${diff}`.where("col1='*'");
var update = UPDATE`Table`.set`col1 = col1 - ${diff}`.where`col1=${"*"}`;
var update = UPDATE`Table`.set`col1 = col1 - ${diff}`.where("col1=", "*");
var update = UPDATE`Table`.set`col1 = col1 - ${diff}`.where`col = ${"*"}`;
var update = UPDATE`Table`.set`col1 = col1 - ${diff}`.where("col1 in ('*', 10)");
var update = UPDATE`Table`.set`col1 = col1 - ${diff}`.where`col1 in ${[ ("*", 10), ]}`;
var update = UPDATE`Table`.set`col1 = col1 - ${diff}`.where({ col1: 10, and: { col2: 11 }, });

var update = UPDATE`Table`.set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where({ col1: "*" });
var update = UPDATE`Table`.set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where("col1='*'");
var update = UPDATE`Table`.set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }).where`col1=${"*"}`;
var update = UPDATE`Table`.set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where("col1=", "*");
var update = UPDATE`Table`.set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }).where`col = ${"*"}`;
var update = UPDATE`Table`.set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where("col1 in ('*', 10)");
var update = UPDATE`Table`.set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }).where`col1 in ${[("*", 10)]}`;
var update = UPDATE`Table`.set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where({ col1: 10, and: { col2: 11 } });

var update = UPDATE`Table`.set({ col1: diff }).where({ col1: "*" });
var update = UPDATE`Table`.set({ col1: diff }).where("col1='*'");
var update = UPDATE`Table`.set({ col1: diff }).where`col1=${"*"}`;
var update = UPDATE`Table`.set({ col1: diff }).where("col1=", "*");
var update = UPDATE`Table`.set({ col1: diff }).where`col = ${"*"}`;
var update = UPDATE`Table`.set({ col1: diff }).where("col1 in ('*', 10)");
var update = UPDATE`Table`.set({ col1: diff }).where`col1 in ${[("*", 10)]}`;
var update = UPDATE`Table`.set({ col1: diff }).where({ col1: 10, and: { col2: 11 } });

/* With `entity` */
var update = UPDATE.entity`Table`.set`col1 = col1 - ${diff}`.where({ col1: "*" });
var update = UPDATE.entity`Table`.set`col1 = col1 - ${diff}`.where("col1='*'");
var update = UPDATE.entity`Table`.set`col1 = col1 - ${diff}`.where`col1=${"*"}`;
var update = UPDATE.entity`Table`.set`col1 = col1 - ${diff}`.where("col1=", "*");
var update = UPDATE.entity`Table`.set`col1 = col1 - ${diff}`.where`col = ${"*"}`;
var update = UPDATE.entity`Table`.set`col1 = col1 - ${diff}`.where("col1 in ('*', 10)");
var update = UPDATE.entity`Table`.set`col1 = col1 - ${diff}`.where`col1 in ${[ ("*", 10), ]}`;
var update = UPDATE.entity`Table`.set`col1 = col1 - ${diff}`.where({ col1: 10, and: { col2: 11 }, });

var update = UPDATE.entity`Table`.set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where({ col1: "*" });
var update = UPDATE.entity`Table`.set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where("col1='*'");
var update = UPDATE.entity`Table`.set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }).where`col1=${"*"}`;
var update = UPDATE.entity`Table`.set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where("col1=", "*");
var update = UPDATE.entity`Table`.set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }).where`col = ${"*"}`;
var update = UPDATE.entity`Table`.set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where("col1 in ('*', 10)");
var update = UPDATE.entity`Table`.set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }).where`col1 in ${[("*", 10)]}`;
var update = UPDATE.entity`Table`.set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where({ col1: 10, and: { col2: 11 } });

var update = UPDATE.entity`Table`.set({ col1: diff }).where({ col1: "*" });
var update = UPDATE.entity`Table`.set({ col1: diff }).where("col1='*'");
var update = UPDATE.entity`Table`.set({ col1: diff }).where`col1=${"*"}`;
var update = UPDATE.entity`Table`.set({ col1: diff }).where("col1=", "*");
var update = UPDATE.entity`Table`.set({ col1: diff }).where`col = ${"*"}`;
var update = UPDATE.entity`Table`.set({ col1: diff }).where("col1 in ('*', 10)");
var update = UPDATE.entity`Table`.set({ col1: diff }).where`col1 in ${[("*", 10)]}`;
var update = UPDATE.entity`Table`.set({ col1: diff }).where({ col1: 10, and: { col2: 11 } });

var update = UPDATE.entity(Table).set`col1 = col1 - ${diff}`.where({ col1: "*" });
var update = UPDATE.entity(Table).set`col1 = col1 - ${diff}`.where("col1='*'");
var update = UPDATE.entity(Table).set`col1 = col1 - ${diff}`.where`col1=${"*"}`;
var update = UPDATE.entity(Table).set`col1 = col1 - ${diff}`.where("col1=", "*");
var update = UPDATE.entity(Table).set`col1 = col1 - ${diff}`.where`col = ${"*"}`;
var update = UPDATE.entity(Table).set`col1 = col1 - ${diff}`.where("col1 in ('*', 10)");
var update = UPDATE.entity(Table).set`col1 = col1 - ${diff}`.where`col1 in ${[ ("*", 10), ]}`;
var update = UPDATE.entity(Table).set`col1 = col1 - ${diff}`.where({ col1: 10, and: { col2: 11 }, });

var update = UPDATE.entity(Table).set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where({ col1: "*" });
var update = UPDATE.entity(Table).set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where("col1='*'");
var update = UPDATE.entity(Table).set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }).where`col1=${"*"}`;
var update = UPDATE.entity(Table).set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where("col1=", "*");
var update = UPDATE.entity(Table).set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }).where`col = ${"*"}`;
var update = UPDATE.entity(Table).set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where("col1 in ('*', 10)");
var update = UPDATE.entity(Table).set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }).where`col1 in ${[("*", 10)]}`;
var update = UPDATE.entity(Table).set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where({ col1: 10, and: { col2: 11 } });

var update = UPDATE.entity(Table).set({ col1: diff }).where({ col1: "*" });
var update = UPDATE.entity(Table).set({ col1: diff }).where("col1='*'");
var update = UPDATE.entity(Table).set({ col1: diff }).where`col1=${"*"}`;
var update = UPDATE.entity(Table).set({ col1: diff }).where("col1=", "*");
var update = UPDATE.entity(Table).set({ col1: diff }).where`col = ${"*"}`;
var update = UPDATE.entity(Table).set({ col1: diff }).where("col1 in ('*', 10)");
var update = UPDATE.entity(Table).set({ col1: diff }).where`col1 in ${[("*", 10)]}`;
var update = UPDATE.entity(Table).set({ col1: diff }).where({ col1: 10, and: { col2: 11 } });

var update = UPDATE.entity("Table").set`col1 = col1 - ${diff}`.where({ col1: "*" });
var update = UPDATE.entity("Table").set`col1 = col1 - ${diff}`.where("col1='*'");
var update = UPDATE.entity("Table").set`col1 = col1 - ${diff}`.where`col1=${"*"}`;
var update = UPDATE.entity("Table").set`col1 = col1 - ${diff}`.where("col1=", "*");
var update = UPDATE.entity("Table").set`col1 = col1 - ${diff}`.where`col = ${"*"}`;
var update = UPDATE.entity("Table").set`col1 = col1 - ${diff}`.where("col1 in ('*', 10)");
var update = UPDATE.entity("Table").set`col1 = col1 - ${diff}`.where`col1 in ${[ ("*", 10), ]}`;
var update = UPDATE.entity("Table").set`col1 = col1 - ${diff}`.where({ col1: 10, and: { col2: 11 }, });

var update = UPDATE.entity("Table").set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where({ col1: "*" });
var update = UPDATE.entity("Table").set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where("col1='*'");
var update = UPDATE.entity("Table").set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }).where`col1=${"*"}`;
var update = UPDATE.entity("Table").set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where("col1=", "*");
var update = UPDATE.entity("Table").set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }).where`col = ${"*"}`;
var update = UPDATE.entity("Table").set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where("col1 in ('*', 10)");
var update = UPDATE.entity("Table").set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }).where`col1 in ${[("*", 10)]}`;
var update = UPDATE.entity("Table").set({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where({ col1: 10, and: { col2: 11 } });

var update = UPDATE.entity("Table").set({ col1: diff }).where({ col1: "*" });
var update = UPDATE.entity("Table").set({ col1: diff }).where("col1='*'");
var update = UPDATE.entity("Table").set({ col1: diff }).where`col1=${"*"}`;
var update = UPDATE.entity("Table").set({ col1: diff }).where("col1=", "*");
var update = UPDATE.entity("Table").set({ col1: diff }).where`col = ${"*"}`;
var update = UPDATE.entity("Table").set({ col1: diff }).where("col1 in ('*', 10)");
var update = UPDATE.entity("Table").set({ col1: diff }).where`col1 in ${[("*", 10)]}`;
var update = UPDATE.entity("Table").set({ col1: diff }).where({ col1: 10, and: { col2: 11 } });

/* ========== UPDATE (entity), with, where ========== */

/* Without `entity` */
var update = UPDATE`Table`.with`col1 = col1 - ${diff}`.where({ col1: "*" });
var update = UPDATE`Table`.with`col1 = col1 - ${diff}`.where("col1='*'");
var update = UPDATE`Table`.with`col1 = col1 - ${diff}`.where`col1=${"*"}`;
var update = UPDATE`Table`.with`col1 = col1 - ${diff}`.where("col1=", "*");
var update = UPDATE`Table`.with`col1 = col1 - ${diff}`.where`col = ${"*"}`;
var update = UPDATE`Table`.with`col1 = col1 - ${diff}`.where("col1 in ('*', 10)");
var update = UPDATE`Table`.with`col1 = col1 - ${diff}`.where`col1 in ${[ ("*", 10), ]}`;
var update = UPDATE`Table`.with`col1 = col1 - ${diff}`.where({ col1: 10, and: { col2: 11 }, });

var update = UPDATE`Table`.with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where({ col1: "*" });
var update = UPDATE`Table`.with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where("col1='*'");
var update = UPDATE`Table`.with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }).where`col1=${"*"}`;
var update = UPDATE`Table`.with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where("col1=", "*");
var update = UPDATE`Table`.with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }).where`col = ${"*"}`;
var update = UPDATE`Table`.with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where("col1 in ('*', 10)");
var update = UPDATE`Table`.with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }).where`col1 in ${[("*", 10)]}`;
var update = UPDATE`Table`.with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where({ col1: 10, and: { col2: 11 } });

var update = UPDATE`Table`.with({ col1: diff }).where({ col1: "*" });
var update = UPDATE`Table`.with({ col1: diff }).where("col1='*'");
var update = UPDATE`Table`.with({ col1: diff }).where`col1=${"*"}`;
var update = UPDATE`Table`.with({ col1: diff }).where("col1=", "*");
var update = UPDATE`Table`.with({ col1: diff }).where`col = ${"*"}`;
var update = UPDATE`Table`.with({ col1: diff }).where("col1 in ('*', 10)");
var update = UPDATE`Table`.with({ col1: diff }).where`col1 in ${[("*", 10)]}`;
var update = UPDATE`Table`.with({ col1: diff }).where({ col1: 10, and: { col2: 11 } });

/* With `entity` */
var update = UPDATE.entity`Table`.with`col1 = col1 - ${diff}`.where({ col1: "*" });
var update = UPDATE.entity`Table`.with`col1 = col1 - ${diff}`.where("col1='*'");
var update = UPDATE.entity`Table`.with`col1 = col1 - ${diff}`.where`col1=${"*"}`;
var update = UPDATE.entity`Table`.with`col1 = col1 - ${diff}`.where("col1=", "*");
var update = UPDATE.entity`Table`.with`col1 = col1 - ${diff}`.where`col = ${"*"}`;
var update = UPDATE.entity`Table`.with`col1 = col1 - ${diff}`.where("col1 in ('*', 10)");
var update = UPDATE.entity`Table`.with`col1 = col1 - ${diff}`.where`col1 in ${[ ("*", 10), ]}`;
var update = UPDATE.entity`Table`.with`col1 = col1 - ${diff}`.where({ col1: 10, and: { col2: 11 }, });

var update = UPDATE.entity`Table`.with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where({ col1: "*" });
var update = UPDATE.entity`Table`.with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where("col1='*'");
var update = UPDATE.entity`Table`.with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }).where`col1=${"*"}`;
var update = UPDATE.entity`Table`.with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where("col1=", "*");
var update = UPDATE.entity`Table`.with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }).where`col = ${"*"}`;
var update = UPDATE.entity`Table`.with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where("col1 in ('*', 10)");
var update = UPDATE.entity`Table`.with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }).where`col1 in ${[("*", 10)]}`;
var update = UPDATE.entity`Table`.with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where({ col1: 10, and: { col2: 11 } });

var update = UPDATE.entity`Table`.with({ col1: diff }).where({ col1: "*" });
var update = UPDATE.entity`Table`.with({ col1: diff }).where("col1='*'");
var update = UPDATE.entity`Table`.with({ col1: diff }).where`col1=${"*"}`;
var update = UPDATE.entity`Table`.with({ col1: diff }).where("col1=", "*");
var update = UPDATE.entity`Table`.with({ col1: diff }).where`col = ${"*"}`;
var update = UPDATE.entity`Table`.with({ col1: diff }).where("col1 in ('*', 10)");
var update = UPDATE.entity`Table`.with({ col1: diff }).where`col1 in ${[("*", 10)]}`;
var update = UPDATE.entity`Table`.with({ col1: diff }).where({ col1: 10, and: { col2: 11 } });

var update = UPDATE.entity(Table).with`col1 = col1 - ${diff}`.where({ col1: "*" });
var update = UPDATE.entity(Table).with`col1 = col1 - ${diff}`.where("col1='*'");
var update = UPDATE.entity(Table).with`col1 = col1 - ${diff}`.where`col1=${"*"}`;
var update = UPDATE.entity(Table).with`col1 = col1 - ${diff}`.where("col1=", "*");
var update = UPDATE.entity(Table).with`col1 = col1 - ${diff}`.where`col = ${"*"}`;
var update = UPDATE.entity(Table).with`col1 = col1 - ${diff}`.where("col1 in ('*', 10)");
var update = UPDATE.entity(Table).with`col1 = col1 - ${diff}`.where`col1 in ${[ ("*", 10), ]}`;
var update = UPDATE.entity(Table).with`col1 = col1 - ${diff}`.where({ col1: 10, and: { col2: 11 }, });

var update = UPDATE.entity(Table).with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where({ col1: "*" });
var update = UPDATE.entity(Table).with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where("col1='*'");
var update = UPDATE.entity(Table).with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }).where`col1=${"*"}`;
var update = UPDATE.entity(Table).with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where("col1=", "*");
var update = UPDATE.entity(Table).with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }).where`col = ${"*"}`;
var update = UPDATE.entity(Table).with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where("col1 in ('*', 10)");
var update = UPDATE.entity(Table).with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }).where`col1 in ${[("*", 10)]}`;
var update = UPDATE.entity(Table).with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where({ col1: 10, and: { col2: 11 } });

var update = UPDATE.entity(Table).with({ col1: diff }).where({ col1: "*" });
var update = UPDATE.entity(Table).with({ col1: diff }).where("col1='*'");
var update = UPDATE.entity(Table).with({ col1: diff }).where`col1=${"*"}`;
var update = UPDATE.entity(Table).with({ col1: diff }).where("col1=", "*");
var update = UPDATE.entity(Table).with({ col1: diff }).where`col = ${"*"}`;
var update = UPDATE.entity(Table).with({ col1: diff }).where("col1 in ('*', 10)");
var update = UPDATE.entity(Table).with({ col1: diff }).where`col1 in ${[("*", 10)]}`;
var update = UPDATE.entity(Table).with({ col1: diff }).where({ col1: 10, and: { col2: 11 } });

var update = UPDATE.entity("Table").with`col1 = col1 - ${diff}`.where({ col1: "*" });
var update = UPDATE.entity("Table").with`col1 = col1 - ${diff}`.where("col1='*'");
var update = UPDATE.entity("Table").with`col1 = col1 - ${diff}`.where`col1=${"*"}`;
var update = UPDATE.entity("Table").with`col1 = col1 - ${diff}`.where("col1=", "*");
var update = UPDATE.entity("Table").with`col1 = col1 - ${diff}`.where`col = ${"*"}`;
var update = UPDATE.entity("Table").with`col1 = col1 - ${diff}`.where("col1 in ('*', 10)");
var update = UPDATE.entity("Table").with`col1 = col1 - ${diff}`.where`col1 in ${[ ("*", 10), ]}`;
var update = UPDATE.entity("Table").with`col1 = col1 - ${diff}`.where({ col1: 10, and: { col2: 11 }, });

var update = UPDATE.entity("Table").with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where({ col1: "*" });
var update = UPDATE.entity("Table").with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where("col1='*'");
var update = UPDATE.entity("Table").with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }).where`col1=${"*"}`;
var update = UPDATE.entity("Table").with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where("col1=", "*");
var update = UPDATE.entity("Table").with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }).where`col = ${"*"}`;
var update = UPDATE.entity("Table").with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where("col1 in ('*', 10)");
var update = UPDATE.entity("Table").with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] }, }).where`col1 in ${[("*", 10)]}`;
var update = UPDATE.entity("Table").with({ col1: { xpr: [{ ref: ["col1"] }, "-", { ref: ["diff"] }] } }).where({ col1: 10, and: { col2: 11 } });

var update = UPDATE.entity("Table").with({ col1: diff }).where({ col1: "*" });
var update = UPDATE.entity("Table").with({ col1: diff }).where("col1='*'");
var update = UPDATE.entity("Table").with({ col1: diff }).where`col1=${"*"}`;
var update = UPDATE.entity("Table").with({ col1: diff }).where("col1=", "*");
var update = UPDATE.entity("Table").with({ col1: diff }).where`col = ${"*"}`;
var update = UPDATE.entity("Table").with({ col1: diff }).where("col1 in ('*', 10)");
var update = UPDATE.entity("Table").with({ col1: diff }).where`col1 in ${[("*", 10)]}`;
var update = UPDATE.entity("Table").with({ col1: diff }).where({ col1: 10, and: { col2: 11 } });
