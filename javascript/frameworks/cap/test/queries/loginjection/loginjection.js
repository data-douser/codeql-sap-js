import cds from '@sap/cds'
const { Books } = cds.entities ('sap.capire.bookshop')

class SampleVulnService extends cds.ApplicationService { init(){

  // contains a sample log injection
  this.on ('submitOrder', async req => {
    const {book,quantity} = req.data

    const LOG = cds.log("nodejs");
    LOG.info("test" + book); // Log injection alert
  })

  this.on('format', (req) => {
    const cds2 = require ('@sap/cds/lib')
    const LOG = cds2.log('cds.log')
    const $ = req.data; LOG.info('format:', $) // Log injection alert
  })

  return super.init()
}}
export { SampleVulnService }
