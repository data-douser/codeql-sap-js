using { advanced_security.log_injection.sample_entities as db_schema } from '../db/schema';

service Service4 @(path: '/service-4') {
  /* Entity to send READ/GET about. */
  entity Service4Entity as projection on db_schema.Entity4 excluding { Attribute4 }

  /* API to talk to other services. */
  action send4 (
    messageToPass: String
  ) returns String;
}
