import cds from '@sap/cds'
const LOG = cds.log("logger");

class SampleVulnService extends cds.ApplicationService {
    init() {
        LOG.info(`[INFO] Environment: ${JSON.stringify(process.env)}`); // CAP log exposure alert
    }
}