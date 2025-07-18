const cds = require("@sap/cds");

class TestService extends cds.ApplicationService {
    init() {
        this.before('READ', 'Test', (req) => req.reply([])) //req
        this.after('READ', this.entities, req => req.target.data) //req
        return super.init()
    }
}
module.exports = TestService

cds.serve('./test-service').with((srv) => {
    const { Test, Service4 } = this.entities
    srv.before('READ', 'Test', (req) => req.reply([])) //req
    srv.on('READ', [Test, Service4], req => req.target.data) //req
    srv.after('READ', req => req.target.data) //req
})