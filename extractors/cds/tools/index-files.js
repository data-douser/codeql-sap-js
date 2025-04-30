"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const cdsCompiler_1 = require("./src/cdsCompiler");
const codeql_1 = require("./src/codeql");
const environment_1 = require("./src/environment");
const filesystem_1 = require("./src/filesystem");
const packageManager_1 = require("./src/packageManager");
const utils_1 = require("./src/utils");
// Validate arguments to this script.
if (!(0, utils_1.validateArguments)(process.argv, 4)) {
    process.exit(0);
}
// Get command-line (CLI) arguments and store them in named variables for clarity.
const responseFile = process.argv[2];
const sourceRoot = process.argv[3];
// Force this script, and any process it spawns, to use the project (source) root
// directory as the current working directory.
process.chdir(sourceRoot);
console.log(`Indexing CDS files in project source directory: ${sourceRoot}`);
const { platform: osPlatform, arch: osPlatformArch } = (0, environment_1.getPlatformInfo)();
console.log(`Detected OS platform=${osPlatform} : arch=${osPlatformArch}`);
// Get the `codeql` (CLI) executable path as this is needed to lookup information
// about the JavaScript extractor (root directory), and to run CodeQL's JavaScript
// extractor via its autobuild script.
const codeqlExePath = (0, environment_1.getCodeQLExePath)();
// Validate that source (code) root directory exists.
if (!(0, filesystem_1.dirExists)(sourceRoot)) {
    const codeqlExe = osPlatform === 'win32' ? 'codeql.exe' : 'codeql';
    console.warn(`'${codeqlExe} database index-files --language cds' terminated early due to internal error: could not find project root directory '${sourceRoot}'.`);
    process.exit(0);
}
// Setup JavaScript extractor environment.
const jsExtractorRoot = (0, environment_1.getJavaScriptExtractorRoot)(codeqlExePath);
if (!jsExtractorRoot) {
    const codeqlExe = osPlatform === 'win32' ? 'codeql.exe' : 'codeql';
    console.warn(`'${codeqlExe} database index-files --language cds' terminated early as CODEQL_EXTRACTOR_JAVASCRIPT_ROOT environment variable is not set.`);
    process.exit(0);
}
// Set environment variables for JavaScript extractor.
process.env.CODEQL_EXTRACTOR_JAVASCRIPT_ROOT = jsExtractorRoot;
(0, environment_1.setupJavaScriptExtractorEnv)();
// Get autobuild script path.
const autobuildScriptPath = (0, environment_1.getAutobuildScriptPath)(jsExtractorRoot);
// Validate all required components.
if (!(0, codeql_1.validateRequirements)(sourceRoot, codeqlExePath, responseFile, autobuildScriptPath, jsExtractorRoot)) {
    process.exit(0);
}
// Read and validate response files.
let responseFiles = [];
try {
    responseFiles = (0, filesystem_1.readResponseFile)(responseFile);
    if (!responseFiles.length) {
        const codeqlExe = osPlatform === 'win32' ? 'codeql.exe' : 'codeql';
        console.warn(`'${codeqlExe} database index-files --language cds' terminated early as response file '${responseFile}' is empty. This is because no CDS files were selected or found.`);
        process.exit(0);
    }
}
catch (err) {
    const codeqlExe = osPlatform === 'win32' ? 'codeql.exe' : 'codeql';
    console.warn(`'${codeqlExe} database index-files --language cds' terminated early as response file '${responseFile}' could not be read due to an error: ${String(err)}`);
    process.exit(0);
}
// Find all package.json directories that have a `@sap/cds` node dependency.
const packageJsonDirs = (0, packageManager_1.findPackageJsonDirs)(responseFiles);
// Install node dependencies in each directory.
console.log('Pre-installing required CDS compiler versions ...');
(0, packageManager_1.installDependencies)(packageJsonDirs);
// Determine the CDS command to use.
const cdsCommand = (0, cdsCompiler_1.determineCdsCommand)();
console.log('Processing CDS files to JSON ...');
// Compile each CDS file to JSON
for (const rawCdsFilePath of responseFiles) {
    try {
        // Use resolved path directly instead of passing through getArg
        const compilationResult = (0, cdsCompiler_1.compileCdsToJson)(rawCdsFilePath, sourceRoot, cdsCommand);
        if (!compilationResult.success && compilationResult.message) {
            console.error(`ERROR: adding diagnostic for source file=${rawCdsFilePath} : ${compilationResult.message} ...`);
            (0, cdsCompiler_1.addCompilationDiagnostic)(rawCdsFilePath, compilationResult.message, codeqlExePath);
        }
    }
    catch (errorMessage) {
        console.error(`ERROR: adding diagnostic for source file=${rawCdsFilePath} : ${String(errorMessage)} ...`);
        (0, cdsCompiler_1.addCompilationDiagnostic)(rawCdsFilePath, String(errorMessage), codeqlExePath);
    }
}
// Configure the "LGTM" index filters for proper extraction.
(0, environment_1.configureLgtmIndexFilters)();
// Run CodeQL's JavaScript extractor to process the compiled JSON files.
const extractorResult = (0, codeql_1.runJavaScriptExtractor)(sourceRoot, autobuildScriptPath);
if (!extractorResult.success && extractorResult.error) {
    console.error(`Error running JavaScript extractor: ${extractorResult.error}`);
}
// Use the `index-file.js` name in the log message as that is the name of the script
// that is actually run by the `codeql database index-files` command. This TypeScript
// file is where the code/logic is edited/implemented, but the runnable script is
// generated by the TypeScript compiler and is named `index-files.js`.
console.log(`Completed run of index-files.js script for CDS extractor.`);
//# sourceMappingURL=index-files.js.map