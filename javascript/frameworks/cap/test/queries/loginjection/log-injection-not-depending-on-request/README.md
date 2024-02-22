# Log Injection PoC

This application demonstrates the possibility of a log injection through communications between several `ApplicationService`s with one dedicated to logging.

The `ApplicationService`s randomly mixes JS class definitions with `cds.service.impl` for diversity.

## It _is not_ a true positive case

Service1 does not emit an event with data dependent on the request parameter, and Service2 is marked as internal, so its request parameter cannot be controlled from the outside.
