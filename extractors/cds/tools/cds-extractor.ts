import { join } from 'path';

import { sync as globSync } from 'glob';

import { determineCdsCommand } from './src/cds';
import { orchestrateCompilation } from './src/cds/compiler/graph';
import {
  handleDebugParserMode,
  handleDebugCompilerMode,
  isDebugMode,
  isDebugParserMode,
  isDebugCompilerMode,
} from './src/cds/parser/debugUtils';
import { buildEnhancedCdsProjectDependencyGraph } from './src/cds/parser/graph';
import { runJavaScriptExtractor } from './src/codeql';
import { addCompilationDiagnostic } from './src/diagnostics';
import { configureLgtmIndexFilters, setupAndValidateEnvironment } from './src/environment';
import { cdsExtractorLog, setSourceRootDirectory } from './src/logging';
import { installDependencies } from './src/packageManager';
import { RunMode } from './src/runMode';
import { validateArguments } from './src/utils';

// Validate the first argument matches an allowed run mode and validate that
// the total number of arguments is correct for the specified run mode.
const validationResult = validateArguments(process.argv);
if (!validationResult.isValid) {
  console.warn(validationResult.usageMessage);
  // Exit with an error code on invalid use of this script.
  process.exit(1);
}

// Get the validated and sanitized arguments
const { runMode, sourceRoot } = validationResult.args!;

// Initialize the unified logging system with the source root directory
setSourceRootDirectory(sourceRoot);

// Check for autobuild mode
if (runMode === (RunMode.AUTOBUILD as string)) {
  cdsExtractorLog('info', 'Autobuild mode is not implemented yet.');
  process.exit(1);
}

// Setup the environment and validate all requirements first, before changing directory
// This ensures we can properly locate the CodeQL tools
const {
  success: envSetupSuccess,
  errorMessages,
  codeqlExePath,
  autobuildScriptPath,
  platformInfo,
} = setupAndValidateEnvironment(sourceRoot);

if (!envSetupSuccess) {
  const codeqlExe = platformInfo.isWindows ? 'codeql.exe' : 'codeql';
  cdsExtractorLog(
    'warn',
    `'${codeqlExe} database index-files --language cds' terminated early due to: ${errorMessages.join(
      ', ',
    )}.`,
  );
  // Exit with an error code when environment setup fails.
  process.exit(1);
}

// Force this script, and any process it spawns, to use the project (source) root
// directory as the current working directory.
process.chdir(sourceRoot);

cdsExtractorLog(
  'info',
  `CodeQL CDS extractor using run mode '${runMode}' for scan of project source root directory '${sourceRoot}'.`,
);

// Using the enhanced project-aware approach to find CDS projects and their dependencies
cdsExtractorLog('info', 'Building enhanced CDS project dependency graph...');

// Build the enhanced dependency graph using the new enhanced parser
let dependencyGraph;

try {
  dependencyGraph = buildEnhancedCdsProjectDependencyGraph(sourceRoot, runMode, __dirname);

  cdsExtractorLog(
    'info',
    `Enhanced dependency graph created with ${dependencyGraph.projects.size} projects and ${dependencyGraph.statusSummary.totalCdsFiles} CDS files`,
  );

  // Handle debug modes early - these modes should exit after completing their specific tasks
  if (isDebugParserMode(runMode)) {
    const debugSuccess = handleDebugParserMode(dependencyGraph, sourceRoot, __dirname);
    process.exit(debugSuccess ? 0 : 1);
  }

  // Log details about discovered projects for debugging
  if (dependencyGraph.projects.size > 0) {
    for (const [projectDir, project] of dependencyGraph.projects.entries()) {
      cdsExtractorLog(
        'info',
        `Enhanced Project: ${projectDir}, Status: ${project.status}, CDS files: ${project.cdsFiles.length}, Files to compile: ${project.cdsFilesToCompile.length}`,
      );
    }
  } else {
    cdsExtractorLog(
      'warn',
      'No CDS projects were detected. This may indicate an issue with project detection logic.',
    );
    // Let's also try to find CDS files directly as a backup check
    try {
      const allCdsFiles = Array.from(
        new Set([
          ...globSync(join(sourceRoot, '**/*.cds'), {
            ignore: ['**/node_modules/**', '**/.git/**'],
          }),
        ]),
      );
      cdsExtractorLog(
        'info',
        `Direct search found ${allCdsFiles.length} CDS files in the source tree.`,
      );
      if (allCdsFiles.length > 0) {
        cdsExtractorLog(
          'info',
          `Sample CDS files: ${allCdsFiles.slice(0, 5).join(', ')}${allCdsFiles.length > 5 ? ', ...' : ''}`,
        );
      }
    } catch (globError) {
      cdsExtractorLog('warn', `Could not perform direct CDS file search: ${String(globError)}`);
    }
  }
} catch (error) {
  cdsExtractorLog('error', `Failed to build enhanced dependency graph: ${String(error)}`);
  // Exit with error since we can't continue without a proper dependency graph
  process.exit(1);
}

// Install dependencies of discovered CAP/CDS projects
cdsExtractorLog('info', 'Installing dependencies for discovered CDS projects...');

const projectCacheDirMap = installDependencies(dependencyGraph, sourceRoot, codeqlExePath);

const cdsFilePathsToProcess: string[] = [];

cdsExtractorLog('info', 'Extracting CDS files from discovered projects...');

// Use the enhanced dependency graph to collect all `.cds` files from each project.
// We want to "extract" all `.cds` files from all projects so that we have a copy
// of each `.cds` source file in the CodeQL database.
for (const project of dependencyGraph.projects.values()) {
  cdsFilePathsToProcess.push(...project.cdsFiles);
}

cdsExtractorLog('info', 'Processing CDS files to JSON using enhanced compilation orchestration...');

// Check if we're running in debug mode
if (isDebugMode(runMode)) {
  cdsExtractorLog(
    'info',
    `Running in ${runMode} mode - enhanced debug information will be collected...`,
  );
}

// Initialize CDS command cache early to avoid repeated testing during compilation
// This is a critical optimization that avoids testing commands for every single file
try {
  determineCdsCommand(undefined, sourceRoot);
  cdsExtractorLog('info', 'CDS command cache initialized successfully');
} catch (error) {
  cdsExtractorLog('warn', `CDS command cache initialization failed: ${String(error)}`);
  // Continue anyway - individual calls will handle fallbacks
}

cdsExtractorLog(
  'info',
  `Found ${cdsFilePathsToProcess.length} total CDS files, ${dependencyGraph.statusSummary.totalCdsFiles} CDS files in dependency graph`,
);

try {
  // Use the new orchestrated compilation approach with debug awareness
  orchestrateCompilation(dependencyGraph, projectCacheDirMap, codeqlExePath, isDebugMode(runMode));

  // Check if we should exit for debug modes after successful compilation
  if (isDebugCompilerMode(runMode)) {
    const debugSuccess = handleDebugCompilerMode(dependencyGraph, runMode);
    process.exit(debugSuccess ? 0 : 1);
  }

  // Handle compilation failures for normal mode
  if (!dependencyGraph.statusSummary.overallSuccess) {
    cdsExtractorLog(
      'error',
      `Compilation completed with failures: ${dependencyGraph.statusSummary.failedCompilations} failed out of ${dependencyGraph.statusSummary.totalCompilationTasks} total tasks`,
    );

    // Add diagnostics for critical errors
    for (const error of dependencyGraph.errors.critical) {
      cdsExtractorLog('error', `Critical error in ${error.phase}: ${error.message}`);
    }

    // Don't exit with error - let the JavaScript extractor run on whatever was compiled
  }
} catch (error) {
  cdsExtractorLog('error', `Compilation orchestration failed: ${String(error)}`);

  // Add diagnostic for the overall failure
  if (cdsFilePathsToProcess.length > 0) {
    addCompilationDiagnostic(
      cdsFilePathsToProcess[0], // Use first file as representative
      `Compilation orchestration failed: ${String(error)}`,
      codeqlExePath,
    );
  }
}

// Configure the "LGTM" index filters for proper extraction.
configureLgtmIndexFilters();

// Run CodeQL's JavaScript extractor to process the compiled JSON files.
const extractorResult = runJavaScriptExtractor(sourceRoot, autobuildScriptPath, codeqlExePath);
if (!extractorResult.success && extractorResult.error) {
  cdsExtractorLog('error', `Error running JavaScript extractor: ${extractorResult.error}`);
}

// Use the `cds-extractor.js` name in the log message as that is the name of the script
// that is actually run by the `codeql database index-files` command. This TypeScript
// file is where the code/logic is edited/implemented, but the runnable script is
// generated by the TypeScript compiler and is named `cds-extractor.js`.
console.log(`Completed run of cds-extractor.js script for CDS extractor.`);
