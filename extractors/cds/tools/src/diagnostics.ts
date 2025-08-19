import { execFileSync } from 'child_process';
import { resolve } from 'path';

import { cdsExtractorLog } from './logging';

/**
 * Severity levels for diagnostics
 */
export enum DiagnosticSeverity {
  Error = 'error',
  Warning = 'warning',
  Note = 'note',
  Recommendation = 'recommendation',
}

/**
 * Base function to add a diagnostic to the CodeQL database
 * @param filePath Path to the file related to the diagnostic
 * @param message The diagnostic message
 * @param codeqlExePath Path to the CodeQL executable
 * @param sourceId The source ID for the diagnostic
 * @param sourceName The source name for the diagnostic
 * @param severity The severity level of the diagnostic
 * @param logPrefix Prefix for the log message
 * @returns True if the diagnostic was added, false otherwise
 */
function addDiagnostic(
  filePath: string,
  message: string,
  codeqlExePath: string,
  sourceId: string,
  sourceName: string,
  severity: DiagnosticSeverity,
  logPrefix: string,
): boolean {
  try {
    execFileSync(codeqlExePath, [
      'database',
      'add-diagnostic',
      '--extractor-name=cds',
      '--ready-for-status-page',
      `--source-id=${sourceId}`,
      `--source-name=${sourceName}`,
      `--severity=${severity}`,
      `--markdown-message=${message}`,
      `--file-path=${resolve(filePath)}`,
      '--',
      `${process.env.CODEQL_EXTRACTOR_CDS_WIP_DATABASE ?? ''}`,
    ]);
    cdsExtractorLog('info', `Added ${severity} diagnostic for ${logPrefix}: ${filePath}`);
    return true;
  } catch (err) {
    cdsExtractorLog(
      'error',
      `Failed to add ${severity} diagnostic for ${logPrefix}=${filePath} : ${String(err)}`,
    );
    return false;
  }
}

/**
 * Add a diagnostic error to the CodeQL database for a failed CDS compilation
 * @param cdsFilePath Path to the CDS file that failed to compile
 * @param errorMessage The error message from the compilation
 * @param codeqlExePath Path to the CodeQL executable
 * @returns True if the diagnostic was added, false otherwise
 */
export function addCompilationDiagnostic(
  cdsFilePath: string,
  errorMessage: string,
  codeqlExePath: string,
): boolean {
  return addDiagnostic(
    cdsFilePath,
    errorMessage,
    codeqlExePath,
    'cds/compilation-failure',
    'Failure to compile one or more SAP CAP CDS files',
    DiagnosticSeverity.Error,
    'source file',
  );
}

/**
 * Add a diagnostic error to the CodeQL database for dependency graph build failure
 * @param sourceRoot Source root directory to use as file context
 * @param errorMessage The error message from dependency graph build
 * @param codeqlExePath Path to the CodeQL executable
 * @returns True if the diagnostic was added, false otherwise
 */
export function addDependencyGraphDiagnostic(
  sourceRoot: string,
  errorMessage: string,
  codeqlExePath: string,
): boolean {
  return addDiagnostic(
    sourceRoot,
    errorMessage,
    codeqlExePath,
    'cds/dependency-graph-failure',
    'CDS project dependency graph build failure',
    DiagnosticSeverity.Error,
    'source root',
  );
}

/**
 * Add a diagnostic error to the CodeQL database for dependency installation failure
 * @param sourceRoot Source root directory to use as file context
 * @param errorMessage The error message from dependency installation
 * @param codeqlExePath Path to the CodeQL executable
 * @returns True if the diagnostic was added, false otherwise
 */
export function addDependencyInstallationDiagnostic(
  sourceRoot: string,
  errorMessage: string,
  codeqlExePath: string,
): boolean {
  return addDiagnostic(
    sourceRoot,
    errorMessage,
    codeqlExePath,
    'cds/dependency-installation-failure',
    'CDS dependency installation failure',
    DiagnosticSeverity.Error,
    'source root',
  );
}

/**
 * Add a diagnostic error to the CodeQL database for environment setup failure
 * @param sourceRoot Source root directory to use as file context
 * @param errorMessage The error message from environment setup
 * @param codeqlExePath Path to the CodeQL executable
 * @returns True if the diagnostic was added, false otherwise
 */
export function addEnvironmentSetupDiagnostic(
  sourceRoot: string,
  errorMessage: string,
  codeqlExePath: string,
): boolean {
  // Use a representative file from source root or the directory itself
  const contextFile = sourceRoot;
  return addDiagnostic(
    contextFile,
    errorMessage,
    codeqlExePath,
    'cds/environment-setup-failure',
    'CDS extractor environment setup failure',
    DiagnosticSeverity.Error,
    'source root',
  );
}

/**
 * Add a diagnostic error to the CodeQL database for a JavaScript extractor failure
 * @param filePath Path to a relevant file for the error context
 * @param errorMessage The error message from the JavaScript extractor
 * @param codeqlExePath Path to the CodeQL executable
 * @returns True if the diagnostic was added, false otherwise
 */
export function addJavaScriptExtractorDiagnostic(
  filePath: string,
  errorMessage: string,
  codeqlExePath: string,
): boolean {
  return addDiagnostic(
    filePath,
    errorMessage,
    codeqlExePath,
    'cds/js-extractor-failure',
    'Failure in JavaScript extractor for SAP CAP CDS files',
    DiagnosticSeverity.Error,
    'extraction file',
  );
}

/**
 * Add a diagnostic warning when no CDS projects are detected
 * @param sourceRoot Source root directory to use as file context
 * @param message The warning message about no CDS projects
 * @param codeqlExePath Path to the CodeQL executable
 * @returns True if the diagnostic was added, false otherwise
 */
export function addNoCdsProjectsDiagnostic(
  sourceRoot: string,
  message: string,
  codeqlExePath: string,
): boolean {
  return addDiagnostic(
    sourceRoot,
    message,
    codeqlExePath,
    'cds/no-cds-projects',
    'No CDS projects detected in source',
    DiagnosticSeverity.Warning,
    'source root',
  );
}
