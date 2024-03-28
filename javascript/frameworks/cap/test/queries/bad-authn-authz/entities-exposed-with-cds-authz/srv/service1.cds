using { advanced_security.log_injection.sample_entities as db_schema } from '../db/schema';

service Service1 @(path: '/service-1', requires: [ "authenticated-user" ]) {
  /* Entity to send READ/GET about. */
  entity Service1Entity @(restrict: [
    { grant: 'WRITE', to: 'Role1' }
    { grant: [ 'WRITE', 'UPDATE' ], to: 'Role2', where: 'Attribute1 = $user.attr' }
  ]) as projection on db_schema.Entity1 excluding { Attribute2 }

  /* API to talk to Service1. */
  action send1 @(requires: "Role3") (
    messageToPass : String
  ) returns String;

  function fun1 @(restrict: [{ to: 'Role4' }]) () returns String;
}
