/** Main retry orchestration logic for CDS compilation failures. */

import { determineCdsCommand } from './command';
import { compileCdsToJson } from './compile';
import { installFullDependencies, needsFullDependencyInstallation } from './installer';
import type { CompilationAttempt, CompilationTask } from './types';
import { identifyTasksRequiringRetry } from './validator';
import { addCompilationDiagnostic } from '../../diagnostics';
import { cdsExtractorLog } from '../../logging';
import type { CdsDependencyGraph, CdsProject } from '../parser/types';

/** Result of retry orchestration for the entire dependency graph */
export interface RetryOrchestrationResult {
  /** Overall success status */
  success: boolean;
  /** Projects that had retry attempts */
  projectsWithRetries: string[];
  /** Total number of tasks that required retry */
  totalTasksRequiringRetry: number;
  /** Total number of successful retry attempts */
  totalSuccessfulRetries: number;
  /** Total number of failed retry attempts */
  totalFailedRetries: number;
  /** Projects where full dependency installation succeeded */
  projectsWithSuccessfulDependencyInstallation: string[];
  /** Projects where full dependency installation failed */
  projectsWithFailedDependencyInstallation: string[];
  /** Duration of retry phase in milliseconds */
  retryDurationMs: number;
  /** Duration of dependency installation in milliseconds */
  dependencyInstallationDurationMs: number;
  /** Duration of retry compilation in milliseconds */
  retryCompilationDurationMs: number;
}

/** Result of executing retry compilation for specific tasks */
export interface RetryExecutionResult {
  /** Project directory */
  projectDir: string;
  /** Tasks that were retried */
  retriedTasks: CompilationTask[];
  /** Number of successful retry attempts */
  successfulRetries: number;
  /** Number of failed retry attempts */
  failedRetries: number;
  /** Whether full dependencies were available for retry */
  fullDependenciesAvailable: boolean;
  /** Retry execution duration in milliseconds */
  executionDurationMs: number;
  /** Error messages from failed retries */
  retryErrors: string[];
}

/**
 * Main retry orchestration function
 * @param dependencyGraph The dependency graph containing compilation tasks
 * @param baseProjectCacheDirMap Original cache directory mappings
 * @param codeqlExePath Path to CodeQL executable for diagnostics
 * @returns Comprehensive retry orchestration results
 */
export function orchestrateRetryAttempts(
  dependencyGraph: CdsDependencyGraph,
  baseProjectCacheDirMap: Map<string, string>,
  codeqlExePath: string,
): RetryOrchestrationResult {
  const startTime = Date.now();
  let dependencyInstallationStartTime = 0;
  let dependencyInstallationEndTime = 0;
  let retryCompilationStartTime = 0;
  let retryCompilationEndTime = 0;

  const result: RetryOrchestrationResult = {
    success: true,
    projectsWithRetries: [],
    totalTasksRequiringRetry: 0,
    totalSuccessfulRetries: 0,
    totalFailedRetries: 0,
    projectsWithSuccessfulDependencyInstallation: [],
    projectsWithFailedDependencyInstallation: [],
    retryDurationMs: 0,
    dependencyInstallationDurationMs: 0,
    retryCompilationDurationMs: 0,
  };

  try {
    // Phase 1: Validate current outputs and identify failed tasks
    cdsExtractorLog('info', 'Identifying tasks requiring retry...');
    const tasksRequiringRetry = identifyTasksRequiringRetry(dependencyGraph);

    if (tasksRequiringRetry.size === 0) {
      cdsExtractorLog('info', 'No tasks require retry - all compilations successful');
      return result;
    }

    // Update retry status tracking
    result.totalTasksRequiringRetry = Array.from(tasksRequiringRetry.values()).reduce(
      (sum, tasks) => sum + tasks.length,
      0,
    );
    dependencyGraph.retryStatus.totalTasksRequiringRetry = result.totalTasksRequiringRetry;

    // Phase 2: Install full dependencies for projects with failed tasks
    cdsExtractorLog('info', 'Installing full dependencies for projects requiring retry...');
    dependencyInstallationStartTime = Date.now();

    for (const [projectDir, failedTasks] of tasksRequiringRetry) {
      const project = dependencyGraph.projects.get(projectDir);
      if (!project) {
        continue;
      }

      if (needsFullDependencyInstallation(project)) {
        try {
          const installResult = installFullDependencies(
            project,
            dependencyGraph.sourceRootDir,
            codeqlExePath,
          );

          // Update project retry status
          project.retryStatus ??= {
            fullDependenciesInstalled: false,
            tasksRequiringRetry: failedTasks.length,
            tasksRetried: 0,
            installationErrors: [],
          };

          if (installResult.success) {
            project.retryStatus.fullDependenciesInstalled = true;
            project.fullDependencyCacheDir = installResult.retryCacheDir;
            result.projectsWithSuccessfulDependencyInstallation.push(projectDir);
            dependencyGraph.retryStatus.projectsWithFullDependencies.add(projectDir);
          } else {
            project.retryStatus.installationErrors = [
              ...(project.retryStatus.installationErrors ?? []),
              installResult.error ?? 'Unknown installation error',
            ];
            result.projectsWithFailedDependencyInstallation.push(projectDir);
          }

          if (installResult.warnings.length > 0) {
            for (const warning of installResult.warnings) {
              dependencyGraph.errors.warnings.push({
                phase: 'retry_dependency_installation',
                message: warning,
                timestamp: new Date(),
                context: projectDir,
              });
            }
          }
        } catch (error) {
          const errorMessage = `Failed to install full dependencies for project ${projectDir}: ${String(error)}`;
          cdsExtractorLog('error', errorMessage);

          dependencyGraph.errors.critical.push({
            phase: 'retry_dependency_installation',
            message: errorMessage,
            timestamp: new Date(),
          });

          result.projectsWithFailedDependencyInstallation.push(projectDir);
        }
      }

      dependencyGraph.retryStatus.projectsRequiringFullDependencies.add(projectDir);
    }

    dependencyInstallationEndTime = Date.now();
    result.dependencyInstallationDurationMs =
      dependencyInstallationEndTime - dependencyInstallationStartTime;

    // Phase 3: Execute retry compilation attempts
    cdsExtractorLog('info', 'Executing retry compilation attempts...');
    retryCompilationStartTime = Date.now();

    for (const [projectDir, failedTasks] of tasksRequiringRetry) {
      const project = dependencyGraph.projects.get(projectDir);
      if (!project) {
        continue;
      }

      const retryExecutionResult = executeRetryCompilation(
        failedTasks,
        project,
        dependencyGraph,
        baseProjectCacheDirMap,
        codeqlExePath,
      );

      result.projectsWithRetries.push(projectDir);
      result.totalSuccessfulRetries += retryExecutionResult.successfulRetries;
      result.totalFailedRetries += retryExecutionResult.failedRetries;

      // Update project retry status
      if (project.retryStatus) {
        project.retryStatus.tasksRetried = retryExecutionResult.retriedTasks.length;
      }
    }

    retryCompilationEndTime = Date.now();
    result.retryCompilationDurationMs = retryCompilationEndTime - retryCompilationStartTime;

    // Phase 4: Update dependency graph with retry results
    updateDependencyGraphWithRetryResults(dependencyGraph, result);

    // Phase 5: Add diagnostics for definitively failed tasks
    addDiagnosticsForFailedTasks(dependencyGraph, codeqlExePath);

    result.success = result.totalSuccessfulRetries > 0 || result.totalTasksRequiringRetry === 0;
  } catch (error) {
    const errorMessage = `Retry orchestration failed: ${String(error)}`;
    cdsExtractorLog('error', errorMessage);

    dependencyGraph.errors.critical.push({
      phase: 'retry_orchestration',
      message: errorMessage,
      timestamp: new Date(),
    });

    result.success = false;
  } finally {
    result.retryDurationMs = Date.now() - startTime;
  }

  return result;
}

/**
 * Executes retry compilation for specific tasks
 * @param tasksToRetry Tasks that need to be retried
 * @param project The project containing the tasks
 * @param dependencyGraph The dependency graph
 * @param baseProjectCacheDirMap Original cache directory mappings
 * @param codeqlExePath Path to CodeQL executable
 * @returns Retry execution results
 */
export function executeRetryCompilation(
  tasksToRetry: CompilationTask[],
  project: CdsProject,
  dependencyGraph: CdsDependencyGraph,
  baseProjectCacheDirMap: Map<string, string>,
  _codeqlExePath: string,
): RetryExecutionResult {
  const startTime = Date.now();

  const result: RetryExecutionResult = {
    projectDir: project.projectDir,
    retriedTasks: [],
    successfulRetries: 0,
    failedRetries: 0,
    fullDependenciesAvailable: Boolean(project.fullDependencyCacheDir),
    executionDurationMs: 0,
    retryErrors: [],
  };

  // Determine cache directory to use for retry
  const cacheDir = project.fullDependencyCacheDir ?? baseProjectCacheDirMap.get(project.projectDir);
  const cdsCommand = determineCdsCommand(cacheDir, dependencyGraph.sourceRootDir);

  cdsExtractorLog(
    'info',
    `Retrying ${tasksToRetry.length} task(s) for project ${project.projectDir} using ${result.fullDependenciesAvailable ? 'full' : 'minimal'} dependencies`,
  );

  for (const task of tasksToRetry) {
    try {
      // Mark task as being retried
      task.retryInfo = {
        hasBeenRetried: true,
        retryReason: 'Output validation failed',
        fullDependenciesInstalled: result.fullDependenciesAvailable,
        retryTimestamp: new Date(),
      };

      // Execute retry compilation attempt
      const retryAttempt = attemptRetryCompilation(task, cdsCommand, cacheDir, dependencyGraph);

      task.retryInfo.retryAttempt = retryAttempt;
      task.attempts.push(retryAttempt);
      result.retriedTasks.push(task);

      if (retryAttempt.result.success) {
        task.status = 'success';
        result.successfulRetries++;
        cdsExtractorLog('info', `Retry successful for task ${task.id}`);
      } else {
        task.status = 'failed';
        task.errorSummary = retryAttempt.error?.message ?? 'Retry compilation failed';
        result.failedRetries++;
        result.retryErrors.push(task.errorSummary);
        cdsExtractorLog('warn', `Retry failed for task ${task.id}: ${task.errorSummary}`);
      }
    } catch (error) {
      const errorMessage = `Failed to retry task ${task.id}: ${String(error)}`;
      result.retryErrors.push(errorMessage);
      result.failedRetries++;
      task.status = 'failed';
      task.errorSummary = errorMessage;
      cdsExtractorLog('error', errorMessage);
    }
  }

  result.executionDurationMs = Date.now() - startTime;

  cdsExtractorLog(
    'info',
    `Retry execution completed for project ${project.projectDir}: ${result.successfulRetries} successful, ${result.failedRetries} failed`,
  );

  return result;
}

/**
 * Updates dependency graph with retry results
 * @param dependencyGraph The dependency graph to update
 * @param retryResults The retry orchestration results
 */
export function updateDependencyGraphWithRetryResults(
  dependencyGraph: CdsDependencyGraph,
  retryResults: RetryOrchestrationResult,
): void {
  // Update overall status summary
  dependencyGraph.retryStatus.totalTasksSuccessfullyRetried = retryResults.totalSuccessfulRetries;
  dependencyGraph.retryStatus.totalRetryAttempts =
    retryResults.totalSuccessfulRetries + retryResults.totalFailedRetries;

  // Update compilation status counters
  dependencyGraph.statusSummary.successfulCompilations += retryResults.totalSuccessfulRetries;
  dependencyGraph.statusSummary.failedCompilations -= retryResults.totalSuccessfulRetries;

  // Update overall success status
  const hasFailures =
    dependencyGraph.statusSummary.failedCompilations > 0 ||
    dependencyGraph.errors.critical.length > 0;
  dependencyGraph.statusSummary.overallSuccess = !hasFailures;
}

/**
 * Add diagnostics only for tasks that remain failed after retry attempts
 * @param dependencyGraph The dependency graph
 * @param codeqlExePath Path to CodeQL executable
 */
function addDiagnosticsForFailedTasks(
  dependencyGraph: CdsDependencyGraph,
  codeqlExePath: string,
): void {
  for (const project of dependencyGraph.projects.values()) {
    for (const task of project.compilationTasks) {
      // Add diagnostics for tasks that are definitively failed
      // This includes both tasks that failed after retry and tasks that failed initially but didn't require retry
      if (task.status === 'failed') {
        const shouldAddDiagnostic = task.retryInfo?.hasBeenRetried ?? !task.retryInfo; // Failed after retry attempt or failed initially and was never retried

        if (shouldAddDiagnostic) {
          for (const sourceFile of task.sourceFiles) {
            addCompilationDiagnostic(
              sourceFile,
              task.errorSummary ?? 'Compilation failed',
              codeqlExePath,
            );
          }
        }
      }
    }
  }
}

/**
 * Attempt compilation with retry-specific context
 * @param task The compilation task to retry
 * @param cdsCommand CDS command to use
 * @param cacheDir Cache directory to use
 * @param dependencyGraph The dependency graph
 * @returns Compilation attempt result
 */
function attemptRetryCompilation(
  task: CompilationTask,
  cdsCommand: string,
  cacheDir: string | undefined,
  dependencyGraph: CdsDependencyGraph,
): CompilationAttempt {
  const attemptId = `${task.id}_retry_${Date.now()}_${Math.random().toString(36).substr(2, 5)}`;
  const startTime = new Date();

  const attempt: CompilationAttempt = {
    id: attemptId,
    cdsCommand,
    cacheDir,
    timestamp: startTime,
    result: {
      success: false,
      timestamp: startTime,
    },
  };

  try {
    // Use the same compilation logic as the original attempt
    const primarySourceFile = task.sourceFiles[0];

    const compilationResult = compileCdsToJson(
      primarySourceFile,
      dependencyGraph.sourceRootDir,
      cdsCommand,
      cacheDir,
      // Convert CDS projects to BasicCdsProject format expected by compileCdsToJson
      new Map(
        Array.from(dependencyGraph.projects.entries()).map(([key, value]) => [
          key,
          {
            cdsFiles: value.cdsFiles,
            cdsFilesToCompile: value.cdsFilesToCompile,
            expectedOutputFiles: value.expectedOutputFiles,
            projectDir: value.projectDir,
            dependencies: value.dependencies,
            imports: value.imports,
            packageJson: value.packageJson,
          },
        ]),
      ),
      task.projectDir,
    );

    attempt.result = {
      ...compilationResult,
      timestamp: startTime,
    };
  } catch (error) {
    attempt.error = {
      message: String(error),
      stack: error instanceof Error ? error.stack : undefined,
    };
  }

  return attempt;
}
