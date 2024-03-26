# Log Injection PoC

This application demonstrates the possibility of a log injection through communications between several `ApplicationService`s with one dedicated to logging.

The `ApplicationService`s randomly mixes JS class definitions with `cds.service.impl` for diversity.

## It _is_ a true positive case

Service1 receives user-controlled data with the event and emits Received1 event, upon which Service2 responds to a Received2 event and logs the data.
