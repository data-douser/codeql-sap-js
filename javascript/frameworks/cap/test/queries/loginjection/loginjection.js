import cds from '@sap/cds'
const { Books } = cds.entities('sap.capire.bookshop')

class SampleVulnService extends cds.ApplicationService {
  init() {
    // contains a sample log injection
    this.on('submitOrder', async req => {
      const { book, quantity } = req.data

      const LOG = cds.log("nodejs");
      LOG.info("CAP:" + book); // CAP log injection alert
      console.log("console:" + book); // non-CAP Log injection alert
    })

    this.on('format', (req) => {
      const cds2 = require('@sap/cds/lib')
      const LOG = cds2.log('cds.log')
      const $ = req.data; LOG.info('format:', $) // CAP log injection alert
    })

    const app = require("express")();
    app.get("search", function handler(req2, res) {
      const { book, quantity } = req2.params.category
      const LOG = cds.log("nodejs");
      LOG.info("CAP:" + book); // CAP log injection alert from non-CAP source
      console.log("console:" + book); // non-CAP Log injection alert from non-CAP source
    });

    return super.init()
  }
}
export { SampleVulnService }
