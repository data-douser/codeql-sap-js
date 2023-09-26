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

// .where()
var select = SELECT.from`Table`.where();

/* SELECTS with property access and method calls */

/*
  - Property: .one
    - const one = await SELECT.one.from (Authors)
    - const [one] = await SELECT.from (Authors)
  - Property: .distinct
    - SELECT.distinct.from (Authors)
  - Method: .columns()
    - SELECT.from `Books` .columns (b => { b.title, b.author.name.as('author') })
    - SELECT.from `Books` .columns `{ title, author.name as author }`
    - SELECT.from `Books` .columns `title, author.name as author`
    - SELECT.from `Books` .columns ( 'title', 'author.name as author')
    - SELECT.from `Books` .columns ( 'title', {ref:['author','name'],as:'author'} )
    - SELECT.from `Books` .columns (['title', {ref:['author','name'],as:'author'} ])  
  - Method: .from()
    - SELECT.from (Books,201)
    - SELECT.from (Books,201, b => { b.ID, b.title })
    - SELECT.one.from (Books) .where ({ID:201})
    - SELECT.one.from (Books) .where ({ID:201}) .columns (b => { b.ID, b.title })
  - Method: .alias()
    - SELECT.from ('Authors').alias('a').where({ exists: SELECT.from('Books').where('author_ID = a.ID')})
  - Method: .where()
  - Method: .having()
  - Method: .groupBy()
  - Method: .orderBy()
  - Method: .limit()
  - Method: forUpdate()
  - Method: forShareLock()
 */

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
