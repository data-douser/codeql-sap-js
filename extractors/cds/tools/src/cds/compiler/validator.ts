/** Validation utilities for CDS compilation output files. */

import { readFileSync } from 'fs';
import { isAbsolute, join } from 'path';

import type { CompilationTask } from './types';
import { fileExists } from '../../filesystem';
import { cdsExtractorLog } from '../../logging';
import type { CdsDependencyGraph } from '../parser/types';

/** Result of validating a single output file */
export interface OutputFileValidationResult {
  /** Whether the file is valid */
  isValid: boolean;
  /** Path to the validated file */
  filePath: string;
  /** Validation error message if validation failed */
  error?: string;
  /** Whether the file exists */
  exists: boolean;
  /** Whether the file contains valid JSON (if it exists) */
  hasValidJson?: boolean;
}

/** Result of validating all outputs for a compilation task */
export interface TaskValidationResult {
  /** Whether all outputs are valid */
  isValid: boolean;
  /** The task that was validated */
  task: CompilationTask;
  /** Validation results for each expected output file */
  fileResults: OutputFileValidationResult[];
  /** Number of valid output files */
  validFileCount: number;
  /** Number of expected output files */
  expectedFileCount: number;
}

/**
 * Validates a single expected output file.
 * @param filePath Path to the output file to validate
 * @returns Validation result with details
 */
export function validateOutputFile(filePath: string): OutputFileValidationResult {
  const result: OutputFileValidationResult = {
    isValid: false,
    filePath,
    exists: false,
  };

  // Check if file exists
  if (!fileExists(filePath)) {
    result.error = 'File does not exist';
    return result;
  }

  result.exists = true;

  // For .cds.json files, validate JSON content
  if (filePath.endsWith('.cds.json') || filePath.endsWith('.json')) {
    try {
      const content = readFileSync(filePath, 'utf8');

      // Check if content is empty
      if (!content.trim()) {
        result.error = 'File is empty';
        return result;
      }

      // Try to parse as JSON
      const parsed: unknown = JSON.parse(content);

      // Basic structure validation for CDS JSON files
      if (typeof parsed !== 'object' || parsed === null) {
        result.error = 'File does not contain a valid JSON object';
        return result;
      }

      result.hasValidJson = true;
      result.isValid = true;
    } catch (error) {
      result.error = `Invalid JSON content: ${String(error)}`;
      return result;
    }
  } else {
    // For non-JSON files, existence is sufficient
    result.isValid = true;
  }

  return result;
}

/**
 * Validates that all expected output files exist for a compilation task.
 * @param task The compilation task to validate
 * @param sourceRoot Source root directory for resolving relative paths
 * @returns Task-level validation result
 */
export function validateTaskOutputs(
  task: CompilationTask,
  sourceRoot: string,
): TaskValidationResult {
  const fileResults: OutputFileValidationResult[] = [];

  for (const expectedOutput of task.expectedOutputFiles) {
    // Resolve the output file path relative to source root
    const absolutePath = isAbsolute(expectedOutput)
      ? expectedOutput
      : join(sourceRoot, expectedOutput);

    const fileResult = validateOutputFile(absolutePath);
    fileResults.push(fileResult);
  }

  const validFileCount = fileResults.filter(r => r.isValid).length;
  const expectedFileCount = task.expectedOutputFiles.length;
  const isValid = validFileCount === expectedFileCount && expectedFileCount > 0;

  return {
    isValid,
    task,
    fileResults,
    validFileCount,
    expectedFileCount,
  };
}

/**
 * Identifies tasks requiring retry based on output validation
 * @param dependencyGraph The dependency graph containing tasks to validate
 * @returns Map of project directory to failed tasks that need retry
 */
export function identifyTasksRequiringRetry(
  dependencyGraph: CdsDependencyGraph,
): Map<string, CompilationTask[]> {
  const tasksRequiringRetry = new Map<string, CompilationTask[]>();

  for (const [projectDir, project] of dependencyGraph.projects.entries()) {
    const failedTasks: CompilationTask[] = [];

    for (const task of project.compilationTasks) {
      // Skip tasks that have already been retried.
      if (task.retryInfo?.hasBeenRetried) {
        continue;
      }

      // Always validate output files exist, regardless of task status.
      const validationResult = validateTaskOutputs(task, dependencyGraph.sourceRootDir);

      if (!validationResult.isValid) {
        failedTasks.push(task);
        cdsExtractorLog(
          'info',
          `Task ${task.id} requires retry: ${validationResult.validFileCount}/${validationResult.expectedFileCount} output files valid (status: ${task.status})`,
        );

        // Update task status to reflect actual file state.
        if (task.status === 'success') {
          cdsExtractorLog(
            'warn',
            `Task ${task.id} was marked as successful but output files are missing or invalid - updating status to failed`,
          );
          task.status = 'failed';
        }
      }
    }

    if (failedTasks.length > 0) {
      tasksRequiringRetry.set(projectDir, failedTasks);
    }
  }

  if (tasksRequiringRetry.size > 0) {
    const totalFailedTasks = Array.from(tasksRequiringRetry.values()).reduce(
      (sum, tasks) => sum + tasks.length,
      0,
    );
    cdsExtractorLog(
      'info',
      `Identified ${totalFailedTasks} task(s) requiring retry across ${tasksRequiringRetry.size} project(s)`,
    );
  }

  return tasksRequiringRetry;
}
