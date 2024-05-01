entity Entity1 @(restrict: [
  { grant: 'READ', to: 'Role1', where: 'Attribute1 = $user' }
]) { }

entity Entity2 @(restrict: [
  { grant: ['READ', 'WRITE'], to: ['Role2', 'Role3'] }
]) { }

entity Entity3 @(restrict: [
  { grant: ['READ','WRITE'], to: 'Role4' },
  { grant: 'READ', where: 'Attribute2 = $user' }
]) { }

entity Entity4 @(restrict: [
  { grant: 'READ', to: 'Role5', where: 'Attribute3 = $user.attribute3' },
  { grant: ['READ','WRITE'], where: 'Attribute4 = $user' },
]) { }

service Service1 {
  entity Entity5 as projection on db.Entity6 { }
  actions {
    @(requires: 'Role6')
    action action1 (attribute5: Integer);
  }
  function function1 @(restrict: [{ to: 'Role7' }]) () returns Integer;
}

service Service2 @(requires: 'authenticated-user') {
  entity Products @(restrict: [
    { grant: 'READ' },
    { grant: 'WRITE', to: 'Role8' },
    { grant: 'action2', to: 'Role9'}
  ]) { }
  actions {
    action action2 (attribute6: Integer);
  }
  entity Entity7 @(restrict: [
    { grant: '*', to: 'Role10', where: 'Attribute7 = $user' }
  ]) { }
  action action3 @(requires: 'Role11') ();
}
