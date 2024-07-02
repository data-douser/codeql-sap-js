using { advanced_security.entities_exposed_with_cds_authz.sample_entities as db_schema } from '../db/schema';

service Service2 @(path: '/service-2', requires: [ 'authenticated-user' ]) {
  /* Entity to send READ/GET about. */
  entity Service2Entity1 @(restrict: [
    { grant: 'WRITE', to: 'Role1' },
    { grant: [ 'WRITE', 'UPDATE' ], to: 'Role2', where: 'Attribute3 = $user.attr' }
  ]) as projection on db_schema.Entity21 excluding { Attribute2 }

  /* Not an error: Inherits the `@requires` annotation of Entity21. */
  entity Service2Entity2 as projection on db_schema.Entity22 excluding { Attribute1 }

  /* API to talk to Service2. */
  actions {
    @(requires: 'Role3')
    action send2 ( messageToPass: String ) returns String;
  }

  function fun2 @(restrict: [{ to: 'Role4' }]) () returns String;
}
