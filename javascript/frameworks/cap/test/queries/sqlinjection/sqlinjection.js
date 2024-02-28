import cds from '@sap/cds'
const { Books } = cds.entities('sap.capire.bookshop')

class SampleVulnService extends cds.ApplicationService {
  init() {
    // contains a sample CAP sql injection
    this.on('submitOrder', async req => {
      const { book, quantity } = req.data

      let { stock } = await SELECT`stock`.from(Books, book)

      let query = SELECT.from`Books`.where(`ID=${book}`)
      let books = await cds.db.run(query) // CAP SQL injection alert

      let books11 = await SELECT.from`Books`.where(`ID=${book}`) // CAP SQL injection alert

      let query2 = SELECT.from`Books`.where('ID=' + book)
      let books2 = await cds.db.run(query2) // CAP SQL injection alert

      let books22 = await SELECT.from`Books`.where('ID=' + book) // CAP SQL injection alert

      let books3 = await SELECT.from`Books`.where`ID=${book}` //safe

      let id = 2
      let books33 = await SELECT.from`Books`.where('ID=' + id) //safe

      let cqn = CQL`SELECT col1, col2, col3 from Books` + book
      let books222 = await cds.db.run(cqn) // CAP SQL injection alert

      let cqn1 = cds.parse.cql(`SELECT * from Books` + book)
      let books111 = await cds.db.run(cqn1) // CAP SQL injection alert

      const pg = require("pg"),
        pool = new pg.Pool(config);
      pool.query(req.params.category, [], function (err, results) { // non-CAP SQL injection alert from CAP source
        // process results
      });

      const app = require("express")();
      app.get("search", function handler(req2, res) {
        pool.query(req2.params.category, [], function (err, results) { // non-CAP SQL injection alert from non-CAP source
          // process results
        });
      });

      return super.init()
    })
  }
}
export { SampleVulnService }