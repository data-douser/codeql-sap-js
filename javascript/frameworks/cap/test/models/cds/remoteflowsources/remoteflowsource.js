const loki = require('lokijs')
const db = new loki('DB')
const testDB = db.addCollection('Test')

module.exports = srv => {
    srv.before('CREATE', 'Test', req => { //source
      const obj = testDB.insert({ test: '' })
      req.data.id = obj.$loki
    })
}