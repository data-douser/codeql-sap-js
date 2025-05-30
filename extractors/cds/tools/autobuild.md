# CodeQL CDS Extractor `autobuild` Re-write Guide

## Goals

The primary goals of this project are to create a more robust, well-tested, and maintainable CodeQL extractor for `.cds` files that implement [Core Data Services][CDS] ([CDS]) as part of the [Cloud Application Programming] ([CAP]) model.

## Overview

This document provides a guide for the multi-step process of re-writing the CodeQL extractor for [CDS] by using an approach based on `autobuild` rather than `index-files`.

This document is meant to be a common reference and a project guide while the iterative re-write is in-progress, especially since there is more to this project than a simple re-write of the scripts that comprise CodeQL's extractor (tool) for [CDS].

## Challenges with the Current Extractor (using `index-files`)

The current extractor for [CDS] is based on `index-files`, which has several limitations and challenges:

1. **Performance**

   The current extractor is slow and inefficient, especially when dealing with large projects or complex [CDS] files. This is due to the way `index-files` processes files, which can lead to long processing times and increased resource usage. There are several performance improvements that could be made to the extractor, but they are all related to avoid work that we either do not need to do or that has already been done.

    - As one example of a performance problem, using the `index-files` approach means that we are provided with a list of all `.cds` files in the project and are expected to index them all, which makes sense for CodeQL (as we want our database to have a copy of every in-scope source code file) but is horribly inefficient from a [CDS] perspective as the [CDS] format allows for a single file to contain multiple [CDS] definitions. The extractor is expected to be able to handle this by parsing the declarative syntax of the `.cds` file in order to understand which other `.cds` files are to be imported as part of that top-level file, meaning that we are expected to avoid duplicate imports of files that are already (and only) used as library-style imports in top-level (project-level) [CDS] files. This is a non-trivial task, and the current extractor does not even try to parse the contents of the `.cds` files to determine which files are actually used in the project. Instead, it simply imports all `.cds` files that are found in the project, which can lead to duplicate imports and increased processing times.

    - Another example of a performance problem is that the current `index-files`-based extractor spends a lot of time installing node dependencies because it runs a `npm install` command in every "CDS project directory" that it finds, which is every directory that contains a `package.json` file and either directly contains a `.cds` file (as a sibling of the `package.json` file) or contains some subdirectory that contains either a `.cds` file or a subdirectory that contains a `.cds` file. This means that the extractor will install these dependencies in a directory that we would rather not make changes in just to be able to use a specific version of `@sap/cds` and/or `@sap/cds-dk` (the dependencies that are needed to run the extractor). This also means that if we have five project that all use the same version of `@sap/cds` and/or `@sap/cds-dk`, we will install that version five separate times in five separate locations, which is both a waste of time and creates a cleanup challenge as the install makes changes to the `package-lock.json` file in each of those five project directories (and also makes changes to the `node_modules` subdirectory of each project directory).

2. **Precision**

   The root-causes of the `Performance` problems can also cause CDS-specific CodeQL queries to produce false-positives in some cases.
   The `.cds` files for a given project must be parsed as a set of related configurations, rather than as independent definitions, in order to avoid false-positives in some CodeQL queries. For example:

   - [bookshop/srv/admin-service.cds](https://github.com/SAP-samples/cloud-cap-samples/blob/main/bookshop/srv/admin-service.cds) is reported by [EntityExposedWithoutAuthn.ql](https://github.com/advanced-security/codeql-sap-js/blob/main/javascript/frameworks[…]hn-authz/EntityExposedWithoutAuthn/EntityExposedWithoutAuthn.ql) as unprotected. This result is actually a false-positive as the service (flagged in the query result) is annotated as `@requires: 'admin'` in a separate [bookshop/srv/access-control.cds](https://github.com/SAP-samples/cloud-cap-samples/blob/main/bookshop/srv/access-control.cds) file (from the same project).

   - Running the current implementation of the CDS extractor for the `bookshop` project will create `admin-service.cds.json` (from `admin-service.cds`) -- where the service is represented without access control; and will also create `access-control.cds.json` (from `access-control.cds`) -- which represent the service again but with access control.

   - In an improved CDS extractor, compiling the whole of the `bookshop` project together should allow us to produce a single `.cds.json` file -- with a single representation of the admin service that it is correctly annotated as having access control.

## Goals for the Future Extractor (using `autobuild`)

The main goals for the `autobuild`-based [CDS] extractor are to:

1. **Improve the Performance of Running the [CDS] Extractor on Large Codebases**:
   The performance problems with the current `index-files`-based [CDS] extractor are compounded when running the extractor on large codebases, where the duplicate import problem is magnified in large projects that make heavy use of library-style imports. The `autobuild`-based extractor will be able to avoid this problem by using a more efficient approach to parsing the `.cds` files and determining which files are actually used in the project. This will allow us to avoid duplicate imports and reduce processing times.

2. **Improve the Precision of Query Results for [CDS] Services**:
   The precision problems of the current [CDS] extractor are also compounded when running the extractor for complex [CAP] projects and/or large codebases, where a lack of project-aware-parsing has a cascading effect as some projects may be imported by other projects and/or may contain multiple `.cds` files that are related to each other. The `autobuild`-based extractor will be able to avoid this problem by using a more efficient approach to parsing the `.cds` files and determining which files are actually used in the project. This will allow us to avoid false-positives in some CodeQL queries and improve the precision of query results for [CDS] services.

All other goals are secondary to and/or in support of the above goals.

## Expected Technical Changes

- The `autobuild.ts` script/code will need to be able to determine its own list of `.cds` files to process when given a "source root" directory to be scanned (recursively) for `.cds` files and will have to maintain some form of state while determining the most efficient way to process all of the applicable [CDS] statements without duplicating work. This will be done by using a combination of parsing the `.cds` files and using a cache to keep track of which files have already been processed. The cache will be stored in a JSON file that will be created and updated as the extractor runs. This will allow the extractor to avoid re-processing files that have already been processed, which will improve performance and reduce resource usage.

- Instead of installing node dependencies directly in each CDS project directory, the CDS extractor should keep track of the unique set of `@sap/cds` and `@sap/cds-dk` dependency combinations that are used by any "project" directory found under the "source root" directory. For each unique combination of `@sap/cds` and `@sap/cds-dk` dependencies, the CDS extractor should also create a (.hidden) directory structure to cache the associated `package.json`, `package-lock.json`, and `./node_modules/`. This will allow the CDS extractor to:
  - be much more efficient in terms of installing [CDS] compiler dependencies;
  - be much more explicit about which version of the [CDS] compiler we are using for a given (sub-)project;
  - avoid making changes to the `package.json` and `package-lock.json` and `node_modules/` within the project directories;
  - avoid installing the same version of these dependencies multiple times;
  - avoid installing project dependencies that we do not actually need for the purpose of running the [CDS] compiler;
  - reduce the overall time it takes to run the [CDS] extractor;
  - minimize and restrict any changes made on the system where the [CDS] extractor is run.

- Use a new `autobuild.ts` script as the main entry point for the extractor's TypeScript code, meaning that the build process will compile the TypeScript code in `autobuild.ts` to JavaScript code in `autobuild.js`, which will then be run as the main entry point for the extractor. Instead of `index-files.cmd` and `index-files.sh`, we will have wrapper scripts such as `autobuild.cmd` and `autobuild.sh` that will be used to run the `autobuild.js` script in different environments (i.e. Windows and Unix-like environments).

- The new [autobuild.ts](./autobuild.ts) script will be a kept as minimal as possible, with object-oriented code patterns used to encapsulate the functionality of the extractor in `.ts` files stored in a new `src` directory (project path would be `extractors/cds/tools/src`). This will allow us to break the extractor into smaller, more manageable pieces, and will also make it easier to test and maintain the code over time. The new `src` directory will contain all of the TypeScript code for the extractor, and will be organized into subdirectories based on functionality. For example, we might have a `parsers` subdirectory for parsing code, a `utils` subdirectory for utility functions, and so on. This will allow us to keep the code organized and easy to navigate.

## References

[CAP]: https://cap.cloud.sap/docs/about/
[CDL]: https://cap.cloud.sap/docs/cds/cdl
[CDS]: https://cap.cloud.sap/docs/cds/

- The [Cloud Application Programming][CAP] Model.
- The [Conceptual Definition Language][CDL] [CDL] is a human-readable language for defining [CDS] models.
- [Core Data Services][CDS] (CDS) in the Cloud Application Programming (CAP) Model.
