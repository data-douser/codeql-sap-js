using { advanced-security.log-injection.sample-entities as db-schema } from '../db/schema';

service Service2 {
  /* Entity to SELECT from. */
  entity Service2Entity as projection on db-schema.Entity2 excluding { Attribute4 }

    /* Async API to talk to Service2. */
  event Received2: {
    messageToPass : String;
  }
}
