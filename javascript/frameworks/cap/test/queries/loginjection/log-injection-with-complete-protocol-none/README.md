# Log Injection PoC

This application demonstrates the possibility of a log injection through communications between several `ApplicationService`s with one dedicated to logging.

The `ApplicationService`s randomly mixes JS class definitions with `cds.service.impl` for diversity.

## It _is not_ a true positive case

Both services are marked as internal with the annotation `@protocol:'None'`, so all request handler parameters are not controlled from the outside.
