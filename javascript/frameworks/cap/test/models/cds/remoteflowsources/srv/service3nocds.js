// This service unit test is a replica of requesthandler.js 
const cds = require("@sap/cds");
class BooksService extends cds.ApplicationService {
    init() {
        const { Books, Authors } = this.entities
        this.on('READ', [Books, Authors], req => req.target.data) // req
        this.on('UPDATE', Books, req => { // req
            let [ID] = req.params
            return Object.assign(Books.data[ID], req.data)
        })
        this.after('READ', req => req.target.data) // req
        this.before('*', req => req.target.data) // req
        return super.init()
    }
}
module.exports = BooksService

cds.serve('./test-service').with((srv) => {
    srv.before('READ', 'Books', (req) => req.reply([])) // req
})