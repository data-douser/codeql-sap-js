# Scaffolding sample application

## Why?

There's not much public CAP projects available for everyone, and even if there are some, they're hard to find and might be quite hard to tailor to our needs, since there may already be much going on in the codebase. So, it might be a better idea to only keep an abstract application where there are only two services talking to each other (to keep things to minimum; more can be added later depending on needs), and an entrypoint server that orchestrates them.

## The abstract application

This abstract application should serve as a scaffolding for any upcoming unit test applications for demonstration / TDD purposes.

The synopsis: A service (`Service1`) receives a piece of data from the outside of the application, and communicates it to the another (`Service2`). What it passes onto the another and how it does it, and even how it receives what user input is up to the problem domain. Some points of customization:

1. A service receives a piece of data
   - By what event? Built-in ones like "READ", or custom ones defined in `.cds`? 
   - What type of data? String? Int?
   - For what? Assembling SQL for db querying? Putting together a request to shoot to a remote service?
   - What data is it associated with what entity/attribute in the accompanying `.cds`? What annotations does it carry?
     - Specifically, what authentication/authorization criteria should accessing these entities meet?
2. From outside the application
   - From where? A remote service? REST API received from an HTTP client like `curl`?
3. And communicates it to the another
   - How? Through async event? Then, what event? Through CQL? Through CRUD-style/REST-style event with `srv.send`?
   - What should the recipient service do with it? Log something? Query a db? Pass it onto some remote service?

## How to run and poke at it

1. At the root of this repository, do an `npm install`.
2. Running `cds serve` will create a server listening on `'http://localhost:4004'`.
3. With your favorite HTTP client (I used restclient.el for emacs), shoot this request:

``` http
POST http://localhost:4004/service-1/send1
Content-Type: application/json

{ "messageToPass": "hihi" }
```
4. Now, there should be this entry in the standard output:

``` shell
[odata] - POST /service-1/send1 
[cds] - connect to service-2 > app-service 
hihi
```
