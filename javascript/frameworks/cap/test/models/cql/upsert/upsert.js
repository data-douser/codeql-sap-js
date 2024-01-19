/* ========== into ========== */
var upsert = UPSERT([
  { col1: "val11", col2: "val12" },
  { col1: "val21", col2: "val22" },
]).into(Table);
var upsert = UPSERT([
  { col1: "val11", col2: "val12" },
  { col1: "val21", col2: "val22" },
]).into("Table");

var upsert = UPSERT.into(Table, [
  { col1: "val11", col2: "val12" },
  { col1: "val21", col2: "val22" },
]);
var upsert = UPSERT.into("Table", [
  { col1: "val11", col2: "val12" },
  { col1: "val21", col2: "val22" },
]);

/* ========== into, entries ========== */
var upsert = UPSERT.into(Table).entries(
  { col1: "val11", col2: "val12" },
  { col1: "val21", col2: "val22" }
);
var upsert = UPSERT.into(Table).entries([
  { col1: "val11", col2: "val12" },
  { col1: "val21", col2: "val22" },
]);
var upsert = UPSERT.into("Table").entries([
  { col1: "val11", col2: "val12" },
  { col1: "val21", col2: "val22" },
]);
var upsert = UPSERT.into("Table").entries([
  { col1: "val11", col2: "val12" },
  { col1: "val21", col2: "val22" },
]);
var upsert = UPSERT.into`Table`.entries([
  { col1: "val11", col2: "val12" },
  { col1: "val21", col2: "val22" },
]);
var upsert = UPSERT.into`Table`.entries([
  { col1: "val11", col2: "val12" },
  { col1: "val21", col2: "val22" },
]);
