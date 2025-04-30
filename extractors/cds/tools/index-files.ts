import { addCompilationDiagnostic, compileCdsToJson, determineCdsCommand } from './src/cdsCompiler';
import { runJavaScriptExtractor, validateRequirements } from './src/codeql';
import {
  configureLgtmIndexFilters,
  getAutobuildScriptPath,
  getCodeQLExePath,
  getJavaScriptExtractorRoot,
  getPlatformInfo,
  setupJavaScriptExtractorEnv,
} from './src/environment';
import { dirExists, readResponseFile } from './src/filesystem';
import { findPackageJsonDirs, installDependencies } from './src/packageManager';
import { validateArguments } from './src/utils';

// Validate arguments to this script.
if (!validateArguments(process.argv, 4)) {
  process.exit(0);
}

// Get command-line (CLI) arguments and store them in named variables for clarity.
const responseFile: string = process.argv[2];
const sourceRoot: string = process.argv[3];

// Force this script, and any process it spawns, to use the project (source) root
// directory as the current working directory.
process.chdir(sourceRoot);

console.log(`Indexing CDS files in project source directory: ${sourceRoot}`);
const { platform: osPlatform, arch: osPlatformArch } = getPlatformInfo();
console.log(`Detected OS platform=${osPlatform} : arch=${osPlatformArch}`);

// Get the `codeql` (CLI) executable path as this is needed to lookup information
// about the JavaScript extractor (root directory), and to run CodeQL's JavaScript
// extractor via its autobuild script.
const codeqlExePath = getCodeQLExePath();

// Validate that source (code) root directory exists.
if (!dirExists(sourceRoot)) {
  const codeqlExe = osPlatform === 'win32' ? 'codeql.exe' : 'codeql';
  console.warn(
    `'${codeqlExe} database index-files --language cds' terminated early due to internal error: could not find project root directory '${sourceRoot}'.`,
  );
  process.exit(0);
}

// Setup JavaScript extractor environment.
const jsExtractorRoot = getJavaScriptExtractorRoot(codeqlExePath);
if (!jsExtractorRoot) {
  const codeqlExe = osPlatform === 'win32' ? 'codeql.exe' : 'codeql';
  console.warn(
    `'${codeqlExe} database index-files --language cds' terminated early as CODEQL_EXTRACTOR_JAVASCRIPT_ROOT environment variable is not set.`,
  );
  process.exit(0);
}

// Set environment variables for JavaScript extractor.
process.env.CODEQL_EXTRACTOR_JAVASCRIPT_ROOT = jsExtractorRoot;
setupJavaScriptExtractorEnv();

// Get autobuild script path.
const autobuildScriptPath = getAutobuildScriptPath(jsExtractorRoot);

// Validate all required components.
if (
  !validateRequirements(
    sourceRoot,
    codeqlExePath,
    responseFile,
    autobuildScriptPath,
    jsExtractorRoot,
  )
) {
  process.exit(0);
}

// Read and validate response files.
let responseFiles: string[] = [];
try {
  responseFiles = readResponseFile(responseFile);
  if (!responseFiles.length) {
    const codeqlExe = osPlatform === 'win32' ? 'codeql.exe' : 'codeql';
    console.warn(
      `'${codeqlExe} database index-files --language cds' terminated early as response file '${responseFile}' is empty. This is because no CDS files were selected or found.`,
    );
    process.exit(0);
  }
} catch (err) {
  const codeqlExe = osPlatform === 'win32' ? 'codeql.exe' : 'codeql';
  console.warn(
    `'${codeqlExe} database index-files --language cds' terminated early as response file '${responseFile}' could not be read due to an error: ${String(
      err,
    )}`,
  );
  process.exit(0);
}

// Find all package.json directories that have a `@sap/cds` node dependency.
const packageJsonDirs = findPackageJsonDirs(responseFiles);

// Install node dependencies in each directory.
console.log('Pre-installing required CDS compiler versions ...');
installDependencies(packageJsonDirs);

// Determine the CDS command to use.
const cdsCommand = determineCdsCommand();

console.log('Processing CDS files to JSON ...');

// Compile each CDS file to JSON
for (const rawCdsFilePath of responseFiles) {
  try {
    // Use resolved path directly instead of passing through getArg
    const compilationResult = compileCdsToJson(rawCdsFilePath, sourceRoot, cdsCommand);

    if (!compilationResult.success && compilationResult.message) {
      console.error(
        `ERROR: adding diagnostic for source file=${rawCdsFilePath} : ${compilationResult.message} ...`,
      );
      addCompilationDiagnostic(rawCdsFilePath, compilationResult.message, codeqlExePath);
    }
  } catch (errorMessage) {
    console.error(
      `ERROR: adding diagnostic for source file=${rawCdsFilePath} : ${String(errorMessage)} ...`,
    );
    addCompilationDiagnostic(rawCdsFilePath, String(errorMessage), codeqlExePath);
  }
}

// Configure the "LGTM" index filters for proper extraction.
configureLgtmIndexFilters();

// Run CodeQL's JavaScript extractor to process the compiled JSON files.
const extractorResult = runJavaScriptExtractor(sourceRoot, autobuildScriptPath);
if (!extractorResult.success && extractorResult.error) {
  console.error(`Error running JavaScript extractor: ${extractorResult.error}`);
}

// Use the `index-file.js` name in the log message as that is the name of the script
// that is actually run by the `codeql database index-files` command. This TypeScript
// file is where the code/logic is edited/implemented, but the runnable script is
// generated by the TypeScript compiler and is named `index-files.js`.
console.log(`Completed run of index-files.js script for CDS extractor.`);
