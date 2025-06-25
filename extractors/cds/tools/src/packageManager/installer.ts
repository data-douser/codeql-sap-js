import { execFileSync } from 'child_process';
import { createHash } from 'crypto';
import { existsSync, mkdirSync, writeFileSync } from 'fs';
import { join, resolve } from 'path';

import { CdsDependencyGraph, EnhancedCdsProject } from '../cds/parser/types';
import { DiagnosticSeverity } from '../diagnostics';
import { cdsExtractorLog } from '../logging';
import { resolveCdsVersions } from './versionResolver';

/**
 * Interface for package.json structure
 */
export interface PackageJson {
  name?: string;
  dependencies?: Record<string, string>;
  devDependencies?: Record<string, string>;
}

/**
 * Represents a unique combination of @sap/cds and @sap/cds-dk dependencies
 */
export interface CdsDependencyCombination {
  cdsVersion: string;
  cdsDkVersion: string;
  hash: string;
  resolvedCdsVersion?: string;
  resolvedCdsDkVersion?: string;
  isFallback?: boolean;
  warning?: string;
}

/**
 * Extracts unique dependency combinations from the dependency graph.
 * @param projects A map of projects from the dependency graph.
 * @returns An array of unique dependency combinations.
 */
function extractUniqueDependencyCombinations(
  projects: Map<string, EnhancedCdsProject>,
): CdsDependencyCombination[] {
  const combinations = new Map<string, CdsDependencyCombination>();

  for (const project of projects.values()) {
    if (!project.packageJson) {
      continue;
    }

    const cdsVersion = project.packageJson.dependencies?.['@sap/cds'] ?? 'latest';
    const cdsDkVersion = project.packageJson.devDependencies?.['@sap/cds-dk'] ?? cdsVersion;

    const hash = createHash('sha256').update(`${cdsVersion}|${cdsDkVersion}`).digest('hex');

    if (!combinations.has(hash)) {
      const resolvedVersions = resolveCdsVersions(cdsVersion, cdsDkVersion);

      const { resolvedCdsVersion, resolvedCdsDkVersion, ...rest } = resolvedVersions;

      combinations.set(hash, {
        cdsVersion,
        cdsDkVersion,
        hash,
        resolvedCdsVersion: resolvedCdsVersion ?? undefined,
        resolvedCdsDkVersion: resolvedCdsDkVersion ?? undefined,
        ...rest,
      });
    }
  }

  return Array.from(combinations.values());
}

/**
 * Add a warning diagnostic for dependency version fallback
 * @param packageJsonPath Path to the package.json file
 * @param warningMessage The warning message
 * @param codeqlExePath Path to the CodeQL executable
 * @returns True if the diagnostic was added, false otherwise
 */
function addDependencyVersionWarning(
  packageJsonPath: string,
  warningMessage: string,
  codeqlExePath: string,
): boolean {
  try {
    execFileSync(codeqlExePath, [
      'database',
      'add-diagnostic',
      '--extractor-name=cds',
      '--ready-for-status-page',
      '--source-id=cds/dependency-version-fallback',
      '--source-name=Using fallback versions for SAP CAP CDS dependencies',
      `--severity=${DiagnosticSeverity.Warning}`,
      `--markdown-message=${warningMessage}`,
      `--file-path=${resolve(packageJsonPath)}`,
      '--',
      `${process.env.CODEQL_EXTRACTOR_CDS_WIP_DATABASE ?? ''}`,
    ]);
    cdsExtractorLog('info', `Added warning diagnostic for dependency fallback: ${packageJsonPath}`);
    return true;
  } catch (err) {
    cdsExtractorLog(
      'error',
      `Failed to add warning diagnostic for ${packageJsonPath}: ${String(err)}`,
    );
    return false;
  }
}

/**
 * Attempt to install dependencies in a cache directory with fallback logic
 * @param cacheDir Cache directory path
 * @param combination Dependency combination to install
 * @param packageJsonPath Optional package.json path for diagnostics
 * @param codeqlExePath Optional CodeQL executable path for diagnostics
 * @returns True if installation succeeded, false otherwise
 */
function installDependenciesInCache(
  cacheDir: string,
  combination: CdsDependencyCombination,
  packageJsonPath?: string,
  codeqlExePath?: string,
): boolean {
  const { resolvedCdsVersion, resolvedCdsDkVersion, isFallback, warning } = combination;

  // Check if node_modules directory already exists in the cache dir
  const nodeModulesExists =
    existsSync(join(cacheDir, 'node_modules', '@sap', 'cds')) &&
    existsSync(join(cacheDir, 'node_modules', '@sap', 'cds-dk'));

  if (nodeModulesExists) {
    cdsExtractorLog(
      'info',
      `Using cached dependencies for @sap/cds@${resolvedCdsVersion} and @sap/cds-dk@${resolvedCdsDkVersion}`,
    );

    // Add warning diagnostic if using fallback versions
    if (isFallback && warning && packageJsonPath && codeqlExePath) {
      addDependencyVersionWarning(packageJsonPath, warning, codeqlExePath);
    }

    return true;
  }

  if (!resolvedCdsVersion || !resolvedCdsDkVersion) {
    cdsExtractorLog('error', 'Cannot install dependencies: no compatible versions found');
    return false;
  }

  // Install dependencies in the cache directory
  cdsExtractorLog(
    'info',
    `Installing @sap/cds@${resolvedCdsVersion} and @sap/cds-dk@${resolvedCdsDkVersion} in cache...`,
  );

  if (isFallback && warning) {
    cdsExtractorLog('warn', warning);
  }

  try {
    execFileSync('npm', ['install', '--quiet', '--no-audit', '--no-fund'], {
      cwd: cacheDir,
      stdio: 'inherit',
    });

    // Add warning diagnostic if using fallback versions
    if (isFallback && warning && packageJsonPath && codeqlExePath) {
      addDependencyVersionWarning(packageJsonPath, warning, codeqlExePath);
    }

    return true;
  } catch (err) {
    const errorMessage = `Failed to install resolved dependencies in cache directory ${cacheDir}: ${err instanceof Error ? err.message : String(err)}`;
    cdsExtractorLog('error', errorMessage);
    return false;
  }
}

/**
 * Install dependencies for CDS projects using a robust cache strategy with fallback logic
 * @param dependencyGraph The dependency graph of the project
 * @param sourceRoot Source root directory
 * @param codeqlExePath Path to the CodeQL executable (optional)
 * @returns Map of project directories to their corresponding cache directories
 */
export function installDependencies(
  dependencyGraph: CdsDependencyGraph,
  sourceRoot: string,
  codeqlExePath?: string,
): Map<string, string> {
  // Sanity check that we found at least one project
  if (dependencyGraph.projects.size === 0) {
    cdsExtractorLog('warn', 'failed to detect any CDS projects for dependency installation.');
    cdsExtractorLog('info', 'This is expected if the source contains no CAP/CDS projects.');
    return new Map<string, string>();
  }

  // Extract unique dependency combinations from all projects with version resolution
  const dependencyCombinations = extractUniqueDependencyCombinations(dependencyGraph.projects);

  if (dependencyCombinations.length === 0) {
    cdsExtractorLog('warn', 'No CDS dependencies found in any project.');
    cdsExtractorLog('info', 'Will attempt to use system-installed CDS tools if available.');
    return new Map<string, string>();
  }

  cdsExtractorLog(
    'info',
    `Found ${dependencyCombinations.length} unique CDS dependency combination(s).`,
  );

  // Create a cache directory under the source root
  const cacheRootDir = join(sourceRoot, '.cds-extractor-cache');
  if (!existsSync(cacheRootDir)) {
    try {
      mkdirSync(cacheRootDir, { recursive: true });
    } catch (err) {
      cdsExtractorLog(
        'warn',
        `Failed to create cache directory: ${err instanceof Error ? err.message : String(err)}`,
      );
      cdsExtractorLog('info', 'Skipping dependency installation due to cache directory failure.');
      return new Map<string, string>();
    }
  }

  // Map to track which cache directory to use for each project
  const projectCacheDirMap = new Map<string, string>();
  let successfulInstallations = 0;

  // Install each unique dependency combination in its own cache directory
  for (const combination of dependencyCombinations) {
    const { cdsVersion, cdsDkVersion, hash } = combination;
    const { resolvedCdsVersion, resolvedCdsDkVersion } = combination;
    const cacheDirName = `cds-${hash}`;
    const cacheDir = join(cacheRootDir, cacheDirName);

    // Create the cache directory if it doesn't exist
    if (!existsSync(cacheDir)) {
      try {
        mkdirSync(cacheDir, { recursive: true });
      } catch (err) {
        cdsExtractorLog(
          'error',
          `Failed to create cache directory for combination ${hash}: ${
            err instanceof Error ? err.message : String(err)
          }`,
        );
        continue;
      }

      // Create a package.json for this dependency combination using resolved versions
      const actualCdsVersion = resolvedCdsVersion ?? cdsVersion;
      const actualCdsDkVersion = resolvedCdsDkVersion ?? cdsDkVersion;

      const packageJson = {
        name: `cds-extractor-cache-${hash}`,
        version: '1.0.0',
        private: true,
        dependencies: {
          '@sap/cds': actualCdsVersion,
          '@sap/cds-dk': actualCdsDkVersion,
        },
      };

      try {
        writeFileSync(join(cacheDir, 'package.json'), JSON.stringify(packageJson, null, 2));
      } catch (err) {
        cdsExtractorLog(
          'error',
          `Failed to create package.json in cache directory: ${
            err instanceof Error ? err.message : String(err)
          }`,
        );
        continue;
      }
    }

    // Try to install dependencies in the cache directory
    // Get the first project package.json path for diagnostic purposes
    const samplePackageJsonPath = Array.from(dependencyGraph.projects.values()).find(
      project => project.packageJson,
    )?.projectDir;
    const packageJsonPath = samplePackageJsonPath
      ? join(sourceRoot, samplePackageJsonPath, 'package.json')
      : undefined;

    const installSuccess = installDependenciesInCache(
      cacheDir,
      combination,
      packageJsonPath,
      codeqlExePath,
    );

    if (!installSuccess) {
      cdsExtractorLog('warn', `Skipping failed dependency combination ${hash}`);
      continue;
    }

    successfulInstallations++;

    // Associate projects with this dependency combination
    for (const [projectDir, project] of dependencyGraph.projects.entries()) {
      if (!project.packageJson) {
        continue;
      }
      const p_cdsVersion = project.packageJson.dependencies?.['@sap/cds'] ?? 'latest';
      const p_cdsDkVersion = project.packageJson.devDependencies?.['@sap/cds-dk'] ?? p_cdsVersion;

      if (p_cdsVersion === combination.cdsVersion && p_cdsDkVersion === combination.cdsDkVersion) {
        projectCacheDirMap.set(projectDir, cacheDir);
      }
    }
  }

  // Log final status
  if (successfulInstallations === 0) {
    cdsExtractorLog('warn', 'Failed to install any dependency combinations.');
  } else if (successfulInstallations < dependencyCombinations.length) {
    cdsExtractorLog(
      'warn',
      `Successfully installed ${successfulInstallations} out of ${dependencyCombinations.length} dependency combinations.`,
    );
  } else {
    cdsExtractorLog('info', 'All dependency combinations installed successfully.');
  }

  return projectCacheDirMap;
}
