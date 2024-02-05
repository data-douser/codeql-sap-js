import cds from '@sap/cds'
const { Books } = cds.entities ('sap.capire.bookshop')

class SampleVulnService extends cds.ApplicationService { init(){

  // contains a sample log injection
  this.on ('submitOrder', async req => {
    const {book,quantity} = req.data

    const LOG = cds.log("nodejs");
    LOG.info("test" + book);
  })

  return super.init()
}}
export { SampleVulnService }
