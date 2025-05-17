import {
  buildCdsProjectDependencyGraph,
  compileCdsToJson,
  determineCdsCommand,
  findProjectForCdsFile,
  writeParserDebugInfo,
} from './src/cds';
import { runJavaScriptExtractor } from './src/codeql';
import { addCompilationDiagnostic } from './src/diagnostics';
import { configureLgtmIndexFilters, setupAndValidateEnvironment } from './src/environment';
import { getCdsFilePathsToProcess } from './src/filesystem';
import { installDependencies } from './src/packageManager';
import { RunMode, validateArguments } from './src/utils';

// Validate arguments to this script.
// The first argument we pass is the expected run mode, which will be extracted from process.argv[2]
// This will determine the correct minimum argument count for validation
const validationResult = validateArguments(process.argv, RunMode.AUTOBUILD);
if (!validationResult.isValid) {
  console.warn(validationResult.usageMessage);
  // Exit with an error code on invalid use of this script.
  process.exit(1);
}

// Get the validated and sanitized arguments
const { runMode, sourceRoot, responseFile } = validationResult.args!;

// Handle debug parser mode
if (runMode === (RunMode.DEBUG_PARSER as string)) {
  console.log('Running CDS Parser in debug mode...');
  console.log(`Source Root Directory: ${sourceRoot}`);

  // Use the project-aware parser as the main entry point
  const scriptDir = __dirname;
  const projectMap = buildCdsProjectDependencyGraph(sourceRoot, runMode, scriptDir);

  if (projectMap.size === 0) {
    console.warn('No CDS projects found. Cannot generate debug information.');
    process.exit(1);
  }

  // Check if debug information was successfully written
  if (runMode === 'debug-parser' && !writeParserDebugInfo(projectMap, sourceRoot, scriptDir)) {
    console.warn('Failed to write debug information.');
    process.exit(1);
  }

  console.log('Debug parser process completed successfully.');
  process.exit(0);
} else if (runMode === (RunMode.AUTOBUILD as string)) {
  console.log('Autobuild mode is not implemented yet.');
  process.exit(1);
}

// Force this script, and any process it spawns, to use the project (source) root
// directory as the current working directory.
process.chdir(sourceRoot);

console.log(
  `INFO: CodeQL CDS extractor using run mode '${runMode}' for scan of project source root directory '${sourceRoot}'.`,
);

// Setup the environment and validate all requirements.
const {
  success: envSetupSuccess,
  errorMessages,
  codeqlExePath,
  autobuildScriptPath,
  platformInfo,
} = setupAndValidateEnvironment(sourceRoot);

if (!envSetupSuccess) {
  const codeqlExe = platformInfo.isWindows ? 'codeql.exe' : 'codeql';
  console.warn(
    `'${codeqlExe} database index-files --language cds' terminated early due to: ${errorMessages.join(
      ', ',
    )}.`,
  );
  // Exit with an error code when environment setup fails.
  process.exit(1);
}

// Only process response file for INDEX_FILES mode
let cdsFilePathsToProcess: string[] = [];
if (runMode === (RunMode.INDEX_FILES as string)) {
  // Validate response file and get the full paths of CDS files to process.
  const filePathsResult = getCdsFilePathsToProcess(responseFile, platformInfo);
  if (!filePathsResult.success) {
    console.warn(filePathsResult.errorMessage);
    // Exit with an error if unable to get a list of `.cds` file paths to process.
    process.exit(1);
  }

  // Get the validated list of CDS files to process
  cdsFilePathsToProcess = filePathsResult.cdsFilePaths;
}

// Using the new project-aware approach to find CDS projects and their dependencies
console.log('Detecting CDS projects and analyzing their structure...');

// Build the project dependency graph using the project-aware parser
const projectMap = buildCdsProjectDependencyGraph(sourceRoot, runMode);

// Install dependencies using the new caching approach
console.log('Installing required CDS compiler versions using cached approach...');
const projectCacheDirMap = installDependencies(projectMap, sourceRoot, codeqlExePath);

// Determine the CDS command to use.
const cdsCommand = determineCdsCommand();

console.log('Processing CDS files to JSON ...');

// Compile each `.cds` file to create a `.cds.json` file.
for (const rawCdsFilePath of cdsFilePathsToProcess) {
  try {
    // Find which project this CDS file belongs to, to use the correct cache directory
    const projectDir = findProjectForCdsFile(rawCdsFilePath, sourceRoot, projectMap);
    const cacheDir = projectDir ? projectCacheDirMap.get(projectDir) : undefined;
    if (cacheDir) {
      console.log(`Using cache directory for ${rawCdsFilePath}: ${cacheDir}`);
    }

    // Use resolved path directly instead of passing through getArg
    const compilationResult = compileCdsToJson(rawCdsFilePath, sourceRoot, cdsCommand, cacheDir);

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
const extractorResult = runJavaScriptExtractor(sourceRoot, autobuildScriptPath, codeqlExePath);
if (!extractorResult.success && extractorResult.error) {
  console.error(`Error running JavaScript extractor: ${extractorResult.error}`);
}

// Use the `cds-extractor.js` name in the log message as that is the name of the script
// that is actually run by the `codeql database index-files` command. This TypeScript
// file is where the code/logic is edited/implemented, but the runnable script is
// generated by the TypeScript compiler and is named `cds-extractor.js`.
console.log(`Completed run of cds-extractor.js script for CDS extractor.`);
