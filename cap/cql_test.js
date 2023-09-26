/* Simplest SELECTs without property accesses or method calls */
var select = SELECT`Table`;

/* SELECTs with property accesses */
var select = SELECT.one.from`Table`;
var select = SELECT.one.from(Table);
var select = SELECT.distinct.from`Table`;
var select = SELECT.distinct.from(Table);

/* SELECTs with method calls */
// .columns()
var select = SELECT.from`Table`.columns`col1, col2`;
var select = SELECT.from`Table`.columns((data) => {
  data.col1, data.col2;
});
var select = SELECT.from`Table`.columns`{ col1, col2 as column }`;
var select = SELECT.from`Table`.columns("col1", "col2 as column");
var select = SELECT.from`Table`.columns([
  "col1",
  { ref: ["col2", "prop"], as: "property" },
]);
var select = SELECT.from`Table`.columns("col1", {
  ref: ["col2", "prop"],
  as: "property",
});

var select = SELECT.from(Table).columns`col1, col2`;
var select = SELECT.from(Table).columns((data) => {
  data.col1, data.col2;
});
var select = SELECT.from(Table).columns`{ col1, col2 as column }`;
var select = SELECT.from(Table).columns("col1", "col2 as column");
var select = SELECT.from(Table).columns([
  "col1",
  { ref: ["col2", "prop"], as: "property" },
]);
var select = SELECT.from(Table).columns("col1", {
  ref: ["col2", "prop"],
  as: "property",
});

// .where()
var select = SELECT.from`Table`.where({ col1: "*" });
var select = SELECT.from`Table`.where("col1='*'");
var select = SELECT.from`Table`.where`"col1='*'"`;
var select = SELECT.from`Table`.where("col1=", "*");
var select = SELECT.from`Table`.where`col = ${"*"}`;
var select = SELECT.from`Table`.where("col1 in ('*', 10)");
var select = SELECT.from`Table`.where`col1 in ${[("*", 10)]}`;
var select = SELECT.from`Table`.where({ col1: 10, and: { col2: 11 } });

// .groupBy()
var select = SELECT.from`Table`.groupBy("col1", "col2");
var select = SELECT.from`Table`.groupBy`col1, col2`;
var select = SELECT.from`Table`.groupBy("col1.prop1", "col2.prop2");
var select = SELECT.from`Table`.groupBy`col1.prop1, col2.prop2`;
var select = SELECT.from`Table`.groupBy(
  { ref: ["col1", "prop1"] },
  { ref: ["col2", "prop2"] }
);

// .having()
var select = SELECT.from`Table`.having({ col1: "*" });
var select = SELECT.from`Table`.having("col1='*'");
var select = SELECT.from`Table`.having`"col1='*'"`;
var select = SELECT.from`Table`.having("col1=", "*");
var select = SELECT.from`Table`.having`col = ${"*"}`;
var select = SELECT.from`Table`.having("col1 in ('*', 10)");
var select = SELECT.from`Table`.having`col1 in ${[("*", 10)]}`;
var select = SELECT.from`Table`.having({ col1: 10, and: { col2: 11 } });

var select = SELECT.from`Table`.groupBy("col1", "col2").having({ col1: "*" });
var select = SELECT.from`Table`.groupBy("col1", "col2").having("col1='*'");
var select = SELECT.from`Table`.groupBy("col1", "col2").having`"col1='*'"`;
var select = SELECT.from`Table`.groupBy("col1", "col2").having("col1=", "*");
var select = SELECT.from`Table`.groupBy("col1", "col2").having`col = ${"*"}`;
var select = SELECT.from`Table`
  .groupBy("col1", "col2")
  .having("col1 in ('*', 10)");
var select = SELECT.from`Table`.groupBy("col1", "col2").having`col1 in ${[
  ("*", 10),
]}`;
var select = SELECT.from`Table`
  .groupBy("col1", "col2")
  .having({ col1: 10, and: { col2: 11 } });

var select = SELECT.from`Table`.groupBy`col1, col2`.having({ col1: "*" });
var select = SELECT.from`Table`.groupBy`col1, col2`.having("col1='*'");
var select = SELECT.from`Table`.groupBy`col1, col2`.having`"col1='*'"`;
var select = SELECT.from`Table`.groupBy`col1, col2`.having("col1=", "*");
var select = SELECT.from`Table`.groupBy`col1, col2`.having`col = ${"*"}`;
var select = SELECT.from`Table`.groupBy`col1, col2`.having("col1 in ('*', 10)");
var select = SELECT.from`Table`.groupBy`col1, col2`.having`col1 in ${[
  ("*", 10),
]}`;
var select = SELECT.from`Table`.groupBy`col1, col2`.having({
  col1: 10,
  and: { col2: 11 },
});

var select = SELECT.from`Table`
  .groupBy("col1.prop1", "col2.prop2")
  .having({ col1: "*" });
var select = SELECT.from`Table`
  .groupBy("col1.prop1", "col2.prop2")
  .having("col1='*'");
var select = SELECT.from`Table`.groupBy("col1.prop1", "col2.prop2")
  .having`"col1='*'"`;
var select = SELECT.from`Table`
  .groupBy("col1.prop1", "col2.prop2")
  .having("col1=", "*");
var select = SELECT.from`Table`.groupBy("col1.prop1", "col2.prop2")
  .having`col = ${"*"}`;
var select = SELECT.from`Table`
  .groupBy("col1.prop1", "col2.prop2")
  .having("col1 in ('*', 10)");
var select = SELECT.from`Table`.groupBy("col1.prop1", "col2.prop2")
  .having`col1 in ${[("*", 10)]}`;
var select = SELECT.from`Table`
  .groupBy("col1.prop1", "col2.prop2")
  .having({ col1: 10, and: { col2: 11 } });

var select = SELECT.from`Table`.groupBy`col1.prop1, col2.prop2`.having({
  col1: "*",
});
var select = SELECT.from`Table`.groupBy`col1.prop1, col2.prop2`.having(
  "col1='*'"
);
var select = SELECT.from`Table`.groupBy`col1.prop1, col2.prop2`
  .having`"col1='*'"`;
var select = SELECT.from`Table`.groupBy`col1.prop1, col2.prop2`.having(
  "col1=",
  "*"
);
var select = SELECT.from`Table`.groupBy`col1.prop1, col2.prop2`
  .having`col = ${"*"}`;
var select = SELECT.from`Table`.groupBy`col1.prop1, col2.prop2`.having(
  "col1 in ('*', 10)"
);
var select = SELECT.from`Table`.groupBy`col1.prop1, col2.prop2`
  .having`col1 in ${[("*", 10)]}`;
var select = SELECT.from`Table`.groupBy`col1.prop1, col2.prop2`.having({
  col1: 10,
  and: { col2: 11 },
});

var select = SELECT.from`Table`
  .groupBy({ ref: ["col1", "prop1"] }, { ref: ["col2", "prop2"] })
  .having({ col1: "*" });
var select = SELECT.from`Table`
  .groupBy({ ref: ["col1", "prop1"] }, { ref: ["col2", "prop2"] })
  .having("col1='*'");
var select = SELECT.from`Table`.groupBy(
  { ref: ["col1", "prop1"] },
  { ref: ["col2", "prop2"] }
).having`"col1='*'"`;
var select = SELECT.from`Table`
  .groupBy({ ref: ["col1", "prop1"] }, { ref: ["col2", "prop2"] })
  .having("col1=", "*");
var select = SELECT.from`Table`.groupBy(
  { ref: ["col1", "prop1"] },
  { ref: ["col2", "prop2"] }
).having`col = ${"*"}`;
var select = SELECT.from`Table`
  .groupBy({ ref: ["col1", "prop1"] }, { ref: ["col2", "prop2"] })
  .having("col1 in ('*', 10)");
var select = SELECT.from`Table`.groupBy(
  { ref: ["col1", "prop1"] },
  { ref: ["col2", "prop2"] }
).having`col1 in ${[("*", 10)]}`;
var select = SELECT.from`Table`
  .groupBy({ ref: ["col1", "prop1"] }, { ref: ["col2", "prop2"] })
  .having({ col1: 10, and: { col2: 11 } });

// .orderBy()
// .limit()
// .forUpdate()
// .forShareLock()

/* SELECTS with property access and method calls */
TODO;

/* CQL tagged function */
CQL`SELECT col1, col2, col3 from Table`;

/* JSON literal queries */

var select = {
  SELECT: {
    one: true,
    columns: [{ ref: ["Foo"] }, { ref: ["Boo"] }, { ref: ["Moo"] }],
    from: { ref: ["Bar"] },
  },
};
