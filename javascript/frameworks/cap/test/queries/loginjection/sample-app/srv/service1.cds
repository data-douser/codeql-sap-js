using { advanced-security.log-injection.sample-entities as db-schema } from '../db/schema';

service Service1 {
  entity Service1Entity as projection on db-schema.Entity1 excluding { Attribute2 } 

  event Received: {
    messageToPass : String;
  }
}