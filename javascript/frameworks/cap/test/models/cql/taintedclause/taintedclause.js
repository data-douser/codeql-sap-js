/* ========== CQL parse usages ========== */
const cds = require('@sap/cds');
let cqn = CQL`SELECT col1, col2, col3 from Table` + userInput //this is actually already captured by taint steps by default
let cqn1 = cds.parse.cql (`SELECT * from Foo`+ userInput) 
let cqn2 = cds.parse.cql (`SELECT * from Foo`) + userInput //not valid
