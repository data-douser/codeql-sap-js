import cds from '@sap/cds'
const { Books } = cds.entities ('sap.capire.bookshop')

class SampleVulnService extends cds.ApplicationService { init(){

  // contains a sample sql injection
  this.on ('submitOrder', async req => {
    const {book,quantity} = req.data

    let {stock} = await SELECT `stock` .from (Books,book) //alert?

    let query = SELECT.from `Books` .where (`ID=${book}`)
    let books = await cds.db.run (query) //alert

    let query2 = SELECT.from `Books` .where ('ID='+book)
    let books2 = await cds.db.run (query2) //alert

    let books3 = await SELECT.from `Books` .where `ID=${book}` //safe
  })

  return super.init()
}}
export { SampleVulnService }
