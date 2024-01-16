import cds from '@sap/cds'
const { Books } = cds.entities ('sap.capire.bookshop')

class SampleVulnService extends cds.ApplicationService { init(){

  // contains a sample sql injection
  this.on ('submitOrder', async req => {
    const {book,quantity} = req.data

    let {stock} = await SELECT `stock` .from (Books,book) //alert?

    let query = SELECT.from `Books` .where (`ID=${book}`)
    let books = await cds.db.run (query) //alert

    let books11 = await SELECT.from `Books` .where (`ID=${book}`) //alert

    let query2 = SELECT.from `Books` .where ('ID='+book)
    let books2 = await cds.db.run (query2) //alert

    let books22 = await SELECT.from `Books` .where ('ID='+book) //alert

    let books3 = await SELECT.from `Books` .where `ID=${book}` //safe

    let id=2
    let books33 = await SELECT.from `Books` .where ('ID='+id) //safe

    let cqn = CQL`SELECT col1, col2, col3 from Books` + book
    let books222 = await cds.db.run (cqn) //alert

    let cqn1 = cds.parse.cql (`SELECT * from Books`+ book) 
    let books111 = await cds.db.run (cqn1) //alert
  })

  return super.init()
}}
export { SampleVulnService }
