/* ========== into ========== */
var insert = INSERT([
  { col1: "val11", col2: "val12" },
  { col1: "val21", col2: "val22" },
]).into(Table);
var insert = INSERT([
  { col1: "val11", col2: "val12" },
  { col1: "val21", col2: "val22" },
]).into("Table");

var insert = INSERT.into(Table, [
  { col1: "val11", col2: "val12" },
  { col1: "val21", col2: "val22" },
]);
var insert = INSERT.into("Table", [
  { col1: "val11", col2: "val12" },
  { col1: "val21", col2: "val22" },
]);

/* ========== into, entries ========== */
var insert = INSERT.into(Table).entries(
  { col1: "val11", col2: "val12" },
  { col1: "val21", col2: "val22" }
);
var insert = INSERT.into(Table).entries([
  { col1: "val11", col2: "val12" },
  { col1: "val21", col2: "val22" },
]);
var insert = INSERT.into("Table").entries([
  { col1: "val11", col2: "val12" },
  { col1: "val21", col2: "val22" },
]);
var insert = INSERT.into("Table").entries([
  { col1: "val11", col2: "val12" },
  { col1: "val21", col2: "val22" },
]);
var insert = INSERT.into`Table`.entries([
  { col1: "val11", col2: "val12" },
  { col1: "val21", col2: "val22" },
]);
var insert = INSERT.into`Table`.entries([
  { col1: "val11", col2: "val12" },
  { col1: "val21", col2: "val22" },
]);

/* ========== into, columns, values ========== */
var insert = INSERT.into(Table)
  .columns("col1", "col2")
  .values("val11", "val12");
var insert = INSERT.into("Table")
  .columns("col1", "col2")
  .values("val11", "val12");
var insert = INSERT.into`Table`
  .columns("col1", "col2")
  .values("val11", "val12");

/* ========== into, columns, rows ========== */
var insert = INSERT.into(Table)
  .columns("col1", "col2")
  .rows([
    ["val11", "val12"],
    ["val21", "val22"],
  ]);
var insert = INSERT.into("Table")
  .columns("col1", "col2")
  .rows([
    ["val11", "val12"],
    ["val21", "val22"],
  ]);
var insert = INSERT.into`Table`.columns("col1", "col2").rows([
  ["val11", "val12"],
  ["val21", "val22"],
]);

/* ========== into, as ========== */
var insert = INSERT.into(Table).as(SELECT.from`Table`.columns`col1, col2`);
var insert = INSERT.into(Table).as(SELECT.from`Table`.where`col1=${"*"}`);
var insert = INSERT.into(Table).as(
  SELECT.from`Table`.groupBy("col1", "col2").having`col1=${"*"}`
);

var insert = INSERT.into("Table").as(SELECT.from`Table`.columns`col1, col2`);
var insert = INSERT.into("Table").as(SELECT.from`Table`.where`col1=${"*"}`);
var insert = INSERT.into("Table").as(
  SELECT.from`Table`.groupBy("col1", "col2").having`col1=${"*"}`
);

var insert = INSERT.into`Table`.as(SELECT.from`Table`.columns`col1, col2`);
var insert = INSERT.into`Table`.as(SELECT.from`Table`.where`col1=${"*"}`);
var insert = INSERT.into`Table`.as(
  SELECT.from`Table`.groupBy("col1", "col2").having`col1=${"*"}`
);
