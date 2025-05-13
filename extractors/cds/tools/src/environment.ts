import { execFileSync } from 'child_process';
import { arch, platform } from 'os';
import { join, resolve } from 'path';

import { dirExists } from './filesystem';

/**
 * Interface for platform information
 */
export interface PlatformInfo {
  platform: string;
  arch: string;
  isWindows: boolean;
  exeExtension: string;
}

/**
 * Interface for environment validation results
 */
export interface EnvironmentSetupResult {
  success: boolean;
  errorMessages: string[];
  codeqlExePath: string;
  jsExtractorRoot: string;
  autobuildScriptPath: string;
  platformInfo: PlatformInfo;
}

/**
 * Get platform information
 * @returns Platform information including OS platform, architecture, and whether it's Windows
 */
export function getPlatformInfo(): PlatformInfo {
  const osPlatform: string = platform();
  const osPlatformArch: string = arch();
  const isWindows = osPlatform === 'win32';
  const exeExtension = isWindows ? '.exe' : '';

  return {
    platform: osPlatform,
    arch: osPlatformArch,
    isWindows,
    exeExtension,
  };
}

/**
 * Get the path to the CodeQL executable
 * @returns The resolved path to the CodeQL executable
 */
export function getCodeQLExePath(): string {
  const platformInfo = getPlatformInfo();
  const codeqlExe: string = platformInfo.isWindows ? 'codeql.exe' : 'codeql';

  // Safely get CODEQL_DIST environment variable
  const codeqlDist = process.env.CODEQL_DIST ?? '';
  return resolve(join(codeqlDist, codeqlExe));
}

/**
 * Get the JavaScript extractor root path
 * @param codeqlExePath The path to the CodeQL executable
 * @returns The JavaScript extractor root path
 */
export function getJavaScriptExtractorRoot(codeqlExePath: string): string {
  let jsExtractorRoot = process.env.CODEQL_EXTRACTOR_JAVASCRIPT_ROOT ?? '';

  if (!jsExtractorRoot) {
    try {
      jsExtractorRoot = execFileSync(codeqlExePath, [
        'resolve',
        'extractor',
        '--language=javascript',
      ])
        .toString()
        .trim();
    } catch (error) {
      console.error(`Error resolving JavaScript extractor root: ${String(error)}`);
      return '';
    }
  }

  return jsExtractorRoot;
}

/**
 * Set JavaScript extractor environment variables using CDS extractor variables
 */
export function setupJavaScriptExtractorEnv(): void {
  process.env.CODEQL_EXTRACTOR_JAVASCRIPT_WIP_DATABASE =
    process.env.CODEQL_EXTRACTOR_CDS_WIP_DATABASE;
  process.env.CODEQL_EXTRACTOR_JAVASCRIPT_DIAGNOSTIC_DIR =
    process.env.CODEQL_EXTRACTOR_CDS_DIAGNOSTIC_DIR;
  process.env.CODEQL_EXTRACTOR_JAVASCRIPT_LOG_DIR = process.env.CODEQL_EXTRACTOR_CDS_LOG_DIR;
  process.env.CODEQL_EXTRACTOR_JAVASCRIPT_SCRATCH_DIR =
    process.env.CODEQL_EXTRACTOR_CDS_SCRATCH_DIR;
  process.env.CODEQL_EXTRACTOR_JAVASCRIPT_TRAP_DIR = process.env.CODEQL_EXTRACTOR_CDS_TRAP_DIR;
  process.env.CODEQL_EXTRACTOR_JAVASCRIPT_SOURCE_ARCHIVE_DIR =
    process.env.CODEQL_EXTRACTOR_CDS_SOURCE_ARCHIVE_DIR;
}

/**
 * Get the path to the autobuild script
 * @param jsExtractorRoot The JavaScript extractor root path
 * @returns The path to the autobuild script
 */
export function getAutobuildScriptPath(jsExtractorRoot: string): string {
  const platformInfo = getPlatformInfo();
  const autobuildScriptName: string = platformInfo.isWindows ? 'autobuild.cmd' : 'autobuild.sh';
  return resolve(join(jsExtractorRoot, 'tools', autobuildScriptName));
}

/**
 * Configure LGTM index filters for CDS files
 */
export function configureLgtmIndexFilters(): void {
  let excludeFilters = '';

  if (process.env.LGTM_INDEX_FILTERS) {
    console.log(`Found $LGTM_INDEX_FILTERS already set to:\n${process.env.LGTM_INDEX_FILTERS}`);
    const allowedExcludePatterns = [join('exclude:**', '*'), join('exclude:**', '*.*')];

    excludeFilters =
      '\n' +
      process.env.LGTM_INDEX_FILTERS.split('\n')
        .filter(
          line =>
            line.startsWith('exclude') &&
            !allowedExcludePatterns.some(pattern => line.includes(pattern)),
        )
        .join('\n');
  }

  // Enable extraction of the .cds.json files only.
  const lgtmIndexFiltersPatterns = [
    join('exclude:**', '*.*'),
    join('include:**', '*.cds.json'),
    join('include:**', '*.cds'),
    join('exclude:**', 'node_modules', '**', '*.*'),
  ].join('\n');

  process.env.LGTM_INDEX_FILTERS = lgtmIndexFiltersPatterns + excludeFilters;
  process.env.LGTM_INDEX_TYPESCRIPT = 'NONE';
  // Configure to copy over the .cds files as well, by pretending they are JSON.
  process.env.LGTM_INDEX_FILETYPES = '.cds:JSON';
}

/**
 * Sets up the environment and validates key components for CDS extractor
 * @param sourceRoot The source root directory
 * @returns The environment setup result
 */
export function setupAndValidateEnvironment(sourceRoot: string): EnvironmentSetupResult {
  const errorMessages: string[] = [];
  const platformInfo = getPlatformInfo();

  // Get the CodeQL executable path
  const codeqlExePath = getCodeQLExePath();

  // Validate that the required source root directory exists
  if (!dirExists(sourceRoot)) {
    errorMessages.push(`project root directory '${sourceRoot}' does not exist`);
  }

  // Setup JavaScript extractor environment
  const jsExtractorRoot = getJavaScriptExtractorRoot(codeqlExePath);
  if (!jsExtractorRoot) {
    errorMessages.push(`CODEQL_EXTRACTOR_JAVASCRIPT_ROOT environment variable is not set`);
  }

  // Set environment variables for JavaScript extractor
  if (jsExtractorRoot) {
    process.env.CODEQL_EXTRACTOR_JAVASCRIPT_ROOT = jsExtractorRoot;
    setupJavaScriptExtractorEnv();
  }

  // Get autobuild script path
  const autobuildScriptPath = jsExtractorRoot ? getAutobuildScriptPath(jsExtractorRoot) : '';

  return {
    success: errorMessages.length === 0,
    errorMessages,
    codeqlExePath,
    jsExtractorRoot,
    autobuildScriptPath,
    platformInfo,
  };
}
