import cds from '@sap/cds'

cds.log('nodejs').trace(code0);
cds.log('nodejs').debug(code0);
cds.log('nodejs').info(code0);
cds.log('nodejs').log(code0);
cds.log('nodejs').warn(code0);
cds.log('nodejs').error(code0);

const code0 = "some-name";
const LOG = cds.log(code0);
LOG.info(code1);

LOG.info(`logging: ${code1}`);
LOG.info(`not actually logging`);