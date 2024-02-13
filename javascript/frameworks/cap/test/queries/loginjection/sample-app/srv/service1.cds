using { advanced-security.log-injection.sample-entities as db-schema } from '../db/schema';

service Service1 {
  /* Entity to send READ about. */
  entity Service1Entity as projection on db-schema.Entity1 excluding { Attribute2 }

  /* Async API for Service1 to speak through. */
  event Received1: {
    messageToPass : String;
  }
}
