import { writeParserDebugInfo } from './debug';
import { CdsDependencyGraph, CdsProject } from './types';
import { cdsExtractorLog } from '../../logging';

/**
 * Handles debug-parser mode execution and cleanup.
 * This function centralizes all debug-parser specific logic.
 *
 * @param dependencyGraph - The enhanced CDS dependency graph
 * @param sourceRootDir - Source root directory
 * @param scriptDir - Directory where the script is running (for debug output)
 * @returns True if debug mode should exit successfully, false if it should exit with error
 */
export function handleDebugParserMode(
  dependencyGraph: CdsDependencyGraph,
  sourceRootDir: string,
  scriptDir: string,
): boolean {
  cdsExtractorLog('info', 'Running CDS Parser in debug mode...');
  cdsExtractorLog('info', `Source Root Directory: ${sourceRootDir}`);

  // Convert enhanced projects back to basic project map for debug output
  const basicProjectMap = new Map<string, CdsProject>();
  for (const [projectDir, enhancedProject] of dependencyGraph.projects.entries()) {
    // Extract the basic CdsProject properties from the enhanced project
    const basicProject: CdsProject = {
      projectDir: enhancedProject.projectDir,
      cdsFiles: enhancedProject.cdsFiles,
      cdsFilesToCompile: enhancedProject.cdsFilesToCompile,
      expectedOutputFiles: enhancedProject.expectedOutputFiles,
      packageJson: enhancedProject.packageJson,
      dependencies: enhancedProject.dependencies,
      imports: enhancedProject.imports,
      compilationConfig: enhancedProject.compilationConfig,
    };
    basicProjectMap.set(projectDir, basicProject);
  }

  // Output the project graph to a debug file
  const debugSuccess = writeParserDebugInfo(basicProjectMap, sourceRootDir, scriptDir);
  if (!debugSuccess) {
    cdsExtractorLog(
      'warn',
      'Failed to write parser debug information. This indicates an empty project map, possibly due to a misconfiguration when calling the parent script.',
    );
  }

  // Return success status based on whether projects were found
  const hasProjects = dependencyGraph.projects.size > 0;
  if (!hasProjects) {
    cdsExtractorLog('warn', 'No CDS projects found. Cannot generate debug information.');
  } else {
    cdsExtractorLog('info', 'Debug parser mode completed successfully.');
  }

  return hasProjects;
}

/**
 * Handles debug-compiler mode execution and cleanup.
 * This function centralizes all debug-compiler specific logic.
 *
 * @param dependencyGraph - The enhanced CDS dependency graph
 * @param runMode - The current run mode
 * @returns True if debug mode should exit successfully, false if it should exit with error
 */
export function handleDebugCompilerMode(
  dependencyGraph: CdsDependencyGraph,
  runMode: string,
): boolean {
  cdsExtractorLog('info', `Running in ${runMode} mode - enhanced debug information collected.`);

  // Check compilation status
  const hasSuccessfulCompilation = dependencyGraph.statusSummary.overallSuccess;

  if (hasSuccessfulCompilation) {
    cdsExtractorLog('info', `${runMode} mode completed successfully.`);
    cdsExtractorLog(
      'info',
      `Compilation summary: ${dependencyGraph.statusSummary.successfulCompilations} successful, ${dependencyGraph.statusSummary.failedCompilations} failed, ${dependencyGraph.statusSummary.skippedCompilations} skipped`,
    );
  } else {
    cdsExtractorLog(
      'warn',
      `${runMode} mode completed with compilation issues: ${dependencyGraph.statusSummary.failedCompilations} failed out of ${dependencyGraph.statusSummary.totalCompilationTasks} total tasks`,
    );

    // Log critical errors for debugging
    for (const error of dependencyGraph.errors.critical) {
      cdsExtractorLog('error', `Critical error in ${error.phase}: ${error.message}`);
    }
  }

  return hasSuccessfulCompilation;
}

/**
 * Determines if the current run mode is a debug mode that should exit early.
 *
 * @param runMode - The current run mode
 * @returns True if this is a debug mode that should exit early
 */
export function isDebugMode(runMode: string): boolean {
  return runMode === 'debug-parser' || runMode === 'debug-compiler';
}

/**
 * Determines if the current run mode is specifically debug-parser.
 *
 * @param runMode - The current run mode
 * @returns True if this is debug-parser mode
 */
export function isDebugParserMode(runMode: string): boolean {
  return runMode === 'debug-parser';
}

/**
 * Determines if the current run mode is specifically debug-compiler.
 *
 * @param runMode - The current run mode
 * @returns True if this is debug-compiler mode
 */
export function isDebugCompilerMode(runMode: string): boolean {
  return runMode === 'debug-compiler';
}
