var delete_ = DELETE.from`Table`.where({ col1: "*" });
var delete_ = DELETE.from`Table`.where("col1='*'");
var delete_ = DELETE.from`Table`.where`col1=${"*"}`;
var delete_ = DELETE.from`Table`.where("col1=", "*");
var delete_ = DELETE.from`Table`.where`col = ${"*"}`;
var delete_ = DELETE.from`Table`.where("col1 in ('*', 10)");
var delete_ = DELETE.from`Table`.where`col1 in ${[("*", 10)]}`;
var delete_ = DELETE.from`Table`.where({ col1: 10, and: { col2: 11 } });

var delete_ = DELETE.from(Table).where({ col1: "*" });
var delete_ = DELETE.from(Table).where("col1='*'");
var delete_ = DELETE.from(Table).where`col1=${"*"}`;
var delete_ = DELETE.from(Table).where("col1=", "*");
var delete_ = DELETE.from(Table).where`col = ${"*"}`;
var delete_ = DELETE.from(Table).where("col1 in ('*', 10)");
var delete_ = DELETE.from(Table).where`col1 in ${[("*", 10)]}`;
var delete_ = DELETE.from(Table).where({ col1: 10, and: { col2: 11 } });