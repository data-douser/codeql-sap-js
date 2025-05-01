# `advanced-security/codeql-sap-js` : `extractors/README.md`

## CodeQL CDS Extractor : Overview

The CodeQL CDS Extractor is a specialized component designed to process and analyze Core Data Services (CDS) files used in SAP Cloud Application Programming (CAP) model applications. This extractor enables CodeQL's static analysis capabilities to detect security vulnerabilities, bugs, and quality issues in CDS files.

Key capabilities of the extractor include:
- Compiling `.cds` files to an intermediate JSON representation
- Handling SAP CAP dependencies and managing compiler versions
- Integrating with the JavaScript extractor for comprehensive analysis
- Converting CDS code to CodeQL's TRAP format for database inclusion
- Supporting both Windows and Unix-like environments through platform-specific wrapper scripts

The extractor operates as an extension to the JavaScript extractor, complementing its ability to analyze JavaScript, TypeScript, and JSON files with support for the CDS domain-specific language.

## CodeQL CDS Extractor : Flowchart

The following flowchart shows the flow of execution for the current implementation of the extractor.

```mermaid
flowchart TD
    COM["`export _build_cmd=<br>$(pwd)/extractors/
javascript/tools/
pre-finalize.sh`"]
    DCR[codeql database create<br>--command=$_build_cmd<br>--language=javascript<br>--search-path=./extractors/<br>--<br>/path/to/database]
    DB[(CodeQL Database)]
    DINIT[codeql database init]
    CRE[codeql resolve extractor]
    JSE[[javascript extractor]]
    DTRAC[codeql database<br>trace-command]
    SPF[[pre-finalize.sh]]
    DIDX[codeql database index-files<br> --language=cds<br>--include-extension=.cds]
    SIF[[index-files.sh]]
    SIT[[index-files.ts/js]]
    NPM[[npm install & build]]
    DETS[[Determine CDS command]]
    FIND[[Find package.json dirs]]
    INST[[Install dependencies]]
    CC[[cds compiler]]
    CDJ([.cds.json files])
    JSA[[javascript extractor<br>autobuild script]]
    TF([CodeQL TRAP files])
    DBF[codeql database finalize<br> -- /path/to/database]

    COM ==> DCR
    DCR ==> |run internal CLI<br>plumbing command| DINIT
    DINIT ----> |--language=javascript| CRE
    CRE -..-> |/extractor/path/javascript| DINIT
    DINIT -.initialize database.-> DB

    DINIT ==> |run the<br>javascript extractor| JSE
    JSE -.-> |extract javascript files:<br>_.html, .js, .json, .ts_| DB
    JSE ==> |run autobuild within<br>the javascript extractor| DTRAC
    
    DTRAC ==> |run the build --command| SPF
    SPF ==> |run codeql index-files<br>for CDS files| DIDX
    DIDX ==> |invoke script via<br>--search-path| SIF
    SIF ==> |runs TypeScript version<br>after npm install| NPM
    NPM ==> |executes compiled<br>index-files.js| SIT
    
    SIT ==> |finds project directories<br>with package.json| FIND
    FIND ==> |install CDS dependencies<br>in project directories| INST
    SIT ==> |determines which<br>cds command to use| DETS
    DETS ==> |processes each CDS file| CC
    
    CC ==> |compile .cds files to<br>create .cds.json files| CDJ
    CDJ -.-> |stored in same location<br>as original .cds files| DB
    
    SIT ==> |configures extraction<br>filters for JSON files| JSA
    JSA ==> |processes .cds.json files<br>via javascript extractor| CDJ
    
    CDJ ==> |javascript extractor<br>generates TRAP files| TF
    TF ==> |imported during<br>database finalization| DBF
    DBF ==> |finalize database and<br>cleanup temporary files| DB
```
