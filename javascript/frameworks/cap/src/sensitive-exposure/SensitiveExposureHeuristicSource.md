# CAP Insertion of Sensitive Information into Log File

If sensitive information is written to a log entry using the CAP Node.js logging API, a malicious user may be able to gain access to user data.

Data that may expose system information such as full path names, system information, usernames and passwords should not be logged.

## Recommendation

CAP applications should not log sensitive information. Sensitive information can include: full path names, system information, usernames, passwords or any personally identifiable information. Make sure to log only information that is not sensitive, or obfuscate/encrypt sensitive information any time that it is logged.

## Examples

This CAP service directly logs the sensitive information. Potential attackers may gain access to this sensitive information when the log output is displayed or when the attacker gains access to the log, and the info is not obfuscated or encrypted.

``` javascript
import cds from '@sap/cds'
const LOG = cds.log("logger");

class SampleVulnService extends cds.ApplicationService {
    init() {
        LOG.info(`[INFO] Environment: ${JSON.stringify(process.env)}`); // CAP log exposure alert
        LOG.info(`[INFO] Environment: ${JSON.stringify(process.env)}`); // CAP log exposure alert
    }
}
```

## References

- OWASP 2021: [Security Logging and Monitoring Failures](https://owasp.org/Top10/A09_2021-Security_Logging_and_Monitoring_Failures/).
- OWASP: [Logging Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html).
- OWASP: [User Privacy Protection Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/User_Privacy_Protection_Cheat_Sheet.html).