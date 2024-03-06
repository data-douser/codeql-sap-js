# CAP Log Injection

If unsanitized user input is written to a log entry using the CAP Node.js logging API, a malicious user may be able to forge new log entries.

CAP Node.js offers a CLRF-safe logging API that should be used for application log entries that are logged as plaintext. If the entry is interpreted as HTML, then arbitrary HTML code my be included to forge log entries.

## Recommendation

CAP applications need to care for escaping user data that is used as input parameter for application logging.  It's recommended to make use of an existing Encoder such as OWASP ESAPI.

## Examples

This CAP service directly logs what the user submitted via the `req` request.

``` javascript
import cds from '@sap/cds'
const { Books } = cds.entities ('sap.capire.bookshop')

class SampleVulnService extends cds.ApplicationService { init(){
  this.on ('submitOrder', async req => {
    const {book,quantity} = req.data
    const LOG = cds.log("nodejs");
    LOG.info("test" + book); // Log injection alert
  })

  return super.init()
}}
```

## References

- OWASP: [Log Injection](https://owasp.org/www-community/attacks/Log_Injection).
- OWASP: [Log Injection Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html).
- SAP CAPire Documentation: [Security Aspects](https://cap.cloud.sap/docs/guides/security/aspects#common-injection-attacks).
