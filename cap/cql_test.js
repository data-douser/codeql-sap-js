/* Simplest SELECTs without property accesses or method calls */
var select = SELECT`Table`;

/* ========== SELECTs with property accesses ========== */
var select = SELECT.one.from`Table`;
var select = SELECT.one.from(Table);
var select = SELECT.distinct.from`Table`;
var select = SELECT.distinct.from(Table);

/*  ========== SELECTs with method calls ========== */
// .columns()
var select = SELECT.from`Table`.columns`col1, col2`;
var select = SELECT.from`Table`.columns((data) => {
  data.col1, data.col2;
});
var select = SELECT.from`Table`.columns`{ col1, col2 as col2Alias }`;
var select = SELECT.from`Table`.columns("col1", "col2 as col2Alias");
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
var select = SELECT.from(Table).columns`{ col1, col2 as col2Alias }`;
var select = SELECT.from(Table).columns("col1", "col2 as col2Alias");
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
var select = SELECT.from`Table`.orderBy`col1.prop1, col2.prop2`;
var select = SELECT.from`Table`.orderBy`col1 asc, col2.prop2`;
var select = SELECT.from`Table`.orderBy`col1.prop1, col2 asc`;
var select = SELECT.from`Table`.orderBy`col1 asc col2 asc`;
var select = SELECT.from`Table`.orderBy`col1.prop1, col2.prop2`;
var select = SELECT.from`Table`.orderBy`col1 desc, col2.prop2`;
var select = SELECT.from`Table`.orderBy`col1.prop1, col2 desc`;
var select = SELECT.from`Table`.orderBy`col1 desc col2 desc`;

// .limit()
var select = SELECT.from`Table`.limit(10);
var select = SELECT.from`Table`.limit(10, 20);
var select = SELECT.from`Table`.limit({ val: 10 });
var select = SELECT.from`Table`.limit({ val: 10 }, { val: 20 });
var select = SELECT.from`Table`.limit({ ref: ["limitVal"] });
var select = SELECT.from`Table`.limit({
  ref: [{ id: "function", args: { p: { ref: ["arg1"] } } }],
});

// .forUpdate()
var select = SELECT.from`Table`.groupBy`col1, col2`
  .having`col = ${"*"}`.forUpdate();

// .forShareLock()
var select = SELECT.from`Table`.groupBy`col1, col2`
  .having`col = ${"*"}`.forShareLock();

/* ========== SELECTS with property access and method calls ========== */
var select = SELECT.distinct.from`Table`.where`col1 in ${[("*", 10)]}`.groupBy(
  "col1",
  "col2"
).having`col1 in ${[("*", 10)]}`.limit({
  ref: [{ id: "function", args: { p: { ref: ["arg1"] } } }],
}).orderBy`col1 desc, col2.prop2`.forShareLock();

/* ========== CQL tagged function ========== */
CQL`SELECT col1, col2, col3 from Table`;

/* ========== JSON literal queries ========== */

var select = {
  SELECT: {
    from: { ref: ["Bar"] },
  },
};

var select = {
  SELECT: {
    one: true,
    columns: [{ ref: ["Foo"] }, { ref: ["Boo"] }, { ref: ["Moo"] }],
    from: { ref: ["Bar"] },
  },
};

var select = {
  SELECT: {
    distinct: true,
    columns: [{ ref: ["Foo"] }, { ref: ["Boo"] }, { ref: ["Moo"] }],
    from: { ref: ["Bar"] },
    limit: {
      rows: { val: 7 },
    },
    where: [{ ref: ["col1"] }, ">", { val: 2 }],
    groupBy: [{ ref: ["col1"] }, { ref: ["col2", "prop2"] }],
  },
};
