/** Full dependency installation utilities for retry scenarios. */

import { execFileSync } from 'child_process';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { join } from 'path';

import { cdsExtractorLog } from '../../logging';
import type { CdsProject } from '../parser/types';

/** Result of full dependency installation for a project */
export interface FullDependencyInstallationResult {
  /** Whether installation was successful */
  success: boolean;
  /** Path to the retry cache directory */
  retryCacheDir: string;
  /** Installation error message if failed */
  error?: string;
  /** Warnings during installation */
  warnings: string[];
  /** Duration of installation in milliseconds */
  durationMs: number;
  /** Whether a timeout occurred */
  timedOut: boolean;
}

/**
 * Installs full dependencies for a project using its package.json
 * @param project The CDS project to install dependencies for
 * @param sourceRoot Source root directory
 * @param codeqlExePath Path to the CodeQL executable for diagnostics
 * @returns Installation result with details
 */
export function installFullDependencies(
  project: CdsProject,
  sourceRoot: string,
  _codeqlExePath: string,
): FullDependencyInstallationResult {
  const startTime = Date.now();

  const result: FullDependencyInstallationResult = {
    success: false,
    retryCacheDir: '',
    warnings: [],
    durationMs: 0,
    timedOut: false,
  };

  try {
    // Create retry-specific cache directory
    const retryCacheDir = createRetryCacheDirectory(project, sourceRoot);
    result.retryCacheDir = retryCacheDir;

    // Create package.json in retry cache directory
    if (!createPackageJsonForRetry(project, sourceRoot, retryCacheDir)) {
      result.error = 'Failed to create package.json for retry';
      return result;
    }

    // Install dependencies using npm
    cdsExtractorLog(
      'info',
      `Installing full dependencies for project ${project.projectDir} in retry cache directory`,
    );

    try {
      execFileSync('npm', ['install', '--quiet', '--no-audit', '--no-fund'], {
        cwd: retryCacheDir,
        stdio: 'inherit',
        timeout: 120000, // 2-minute timeout
      });

      result.success = true;
      cdsExtractorLog(
        'info',
        `Successfully installed full dependencies for project ${project.projectDir}`,
      );
    } catch (execError) {
      if (execError instanceof Error && 'signal' in execError && execError.signal === 'SIGTERM') {
        result.timedOut = true;
        result.error = 'Dependency installation timed out';
      } else {
        result.error = `npm install failed: ${String(execError)}`;
      }

      // Still attempt retry compilation even if dependency installation fails (optimistic approach)
      result.warnings.push(
        `Dependency installation failed but will still attempt retry compilation: ${result.error}`,
      );
      cdsExtractorLog('warn', result.warnings[0]);
    }
  } catch (error) {
    result.error = `Failed to install full dependencies: ${String(error)}`;
    cdsExtractorLog('error', result.error);
  } finally {
    result.durationMs = Date.now() - startTime;
  }

  return result;
}

/**
 * Determines if a project needs full dependency installation
 * @param project The CDS project to check
 * @returns Whether full dependency installation is needed
 */
export function needsFullDependencyInstallation(project: CdsProject): boolean {
  // Check if already installed
  if (project.retryStatus?.fullDependenciesInstalled) {
    return false;
  }

  // Check if project has failed tasks that could benefit from full dependencies
  const hasFailedTasks = project.compilationTasks.some(
    task => task.status === 'failed' && !task.retryInfo?.hasBeenRetried,
  );

  return hasFailedTasks && project.packageJson !== undefined;
}

/**
 * Creates retry-specific cache directory for a project
 * @param project The CDS project
 * @param sourceRoot Source root directory
 * @returns Path to the created retry cache directory
 */
export function createRetryCacheDirectory(project: CdsProject, sourceRoot: string): string {
  const cacheSubDirName = '.cds-extractor-cache';
  const cacheRootDir = join(sourceRoot, cacheSubDirName);

  // Generate unique retry cache directory name
  const projectHash = Buffer.from(project.projectDir).toString('base64').replace(/[/+=]/g, '_');
  const timestamp = Date.now();
  const retryCacheDirName = `retry-${projectHash}-${timestamp}`;
  const retryCacheDir = join(cacheRootDir, retryCacheDirName);

  // Create cache root directory if it doesn't exist
  if (!existsSync(cacheRootDir)) {
    try {
      mkdirSync(cacheRootDir, { recursive: true });
      cdsExtractorLog('info', `Created cache root directory: ${cacheRootDir}`);
    } catch (error) {
      throw new Error(`Failed to create cache root directory: ${String(error)}`);
    }
  }

  // Create retry-specific cache directory
  try {
    mkdirSync(retryCacheDir, { recursive: true });
    cdsExtractorLog('info', `Created retry cache directory: ${retryCacheDirName}`);
  } catch (error) {
    throw new Error(`Failed to create retry cache directory: ${String(error)}`);
  }

  return retryCacheDir;
}

/**
 * Creates a package.json file in the retry cache directory based on the project's original package.json
 * @param project The CDS project
 * @param sourceRoot Source root directory
 * @param retryCacheDir Path to the retry cache directory
 * @returns Whether package.json creation was successful
 */
function createPackageJsonForRetry(
  project: CdsProject,
  sourceRoot: string,
  retryCacheDir: string,
): boolean {
  if (!project.packageJson) {
    cdsExtractorLog('warn', `No package.json found for project ${project.projectDir}`);
    return false;
  }

  try {
    // Check if original package-lock.json exists
    const originalPackageLockPath = join(sourceRoot, project.projectDir, 'package-lock.json');
    let packageLockContent: unknown = undefined;

    if (existsSync(originalPackageLockPath)) {
      try {
        const lockContent = readFileSync(originalPackageLockPath, 'utf8');
        packageLockContent = JSON.parse(lockContent);
        cdsExtractorLog('info', `Found package-lock.json for project ${project.projectDir}`);
      } catch (error) {
        cdsExtractorLog(
          'warn',
          `Failed to read package-lock.json for project ${project.projectDir}: ${String(error)}`,
        );
      }
    }

    // Create package.json with all dependencies
    const retryPackageJson: Record<string, unknown> = {
      name: `${project.packageJson.name ?? 'unknown'}-retry`,
      version: project.packageJson.version ?? '1.0.0',
      private: true,
      dependencies: {
        ...(project.packageJson.dependencies ?? {}),
        ...(project.packageJson.devDependencies ?? {}), // Include dev dependencies as dependencies
      },
    };

    // Copy other relevant fields that might affect dependency resolution
    if (project.packageJson.engines) {
      retryPackageJson.engines = project.packageJson.engines;
    }
    if (project.packageJson.peerDependencies) {
      retryPackageJson.peerDependencies = project.packageJson.peerDependencies;
    }

    // Write package.json
    const packageJsonPath = join(retryCacheDir, 'package.json');
    writeFileSync(packageJsonPath, JSON.stringify(retryPackageJson, null, 2));
    cdsExtractorLog('info', `Created retry package.json for project ${project.projectDir}`);

    // Copy package-lock.json if it exists
    if (packageLockContent) {
      const packageLockPath = join(retryCacheDir, 'package-lock.json');
      writeFileSync(packageLockPath, JSON.stringify(packageLockContent, null, 2));
      cdsExtractorLog('info', `Copied package-lock.json for project ${project.projectDir}`);
    }

    return true;
  } catch (error) {
    cdsExtractorLog('error', `Failed to create package.json for retry: ${String(error)}`);
    return false;
  }
}
