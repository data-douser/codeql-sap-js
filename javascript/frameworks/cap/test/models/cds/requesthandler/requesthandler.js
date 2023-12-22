const cds = require("@sap/cds");
class BooksService extends cds.ApplicationService {
    init(){
        const { Books, Authors } = this.entities
        this.on ('READ',[Books,Authors], req => req.target.data) 
        this.on ('UPDATE',Books, req => { 
            let [ ID ] = req.params
            return Object.assign (Books.data[ID], req.data)
        })
    return super.init()
    }
}
module.exports = BooksService

cds.serve('./test-service') .with ((srv) => {
        srv.on ('READ','Books', (req) => req.reply([])) //currently this handler is not detected
    })