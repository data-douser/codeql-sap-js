import { execFileSync } from 'child_process';
import { existsSync, readFileSync } from 'fs';
import { join, dirname, resolve } from 'path';

/**
 * Interface for package.json structure
 */
export interface PackageJson {
  name?: string;
  dependencies?: Record<string, string>;
  devDependencies?: Record<string, string>;
}

/**
 * Find directories containing package.json with @sap/cds dependency
 * @param filePaths List of CDS file paths to check
 * @returns Set of directories containing relevant package.json files
 */
export function findPackageJsonDirs(filePaths: string[]): Set<string> {
  const packageJsonDirs = new Set<string>();

  filePaths.forEach(file => {
    let dir = dirname(resolve(file));
    const rootDir = dirname(dir); // Keep track of the root to avoid infinite loop

    while (dir !== rootDir && rootDir !== dir) {
      // Check until we reach the root directory
      const packageJsonPath = join(dir, 'package.json');
      if (existsSync(packageJsonPath)) {
        try {
          const rawData = readFileSync(packageJsonPath, 'utf-8');
          const packageJsonData = JSON.parse(rawData) as PackageJson;

          if (
            packageJsonData.name &&
            packageJsonData.dependencies &&
            typeof packageJsonData.dependencies === 'object' &&
            Object.keys(packageJsonData.dependencies).includes('@sap/cds')
          ) {
            packageJsonDirs.add(dir);
            break;
          }
        } catch (error) {
          console.warn(
            `Warning: Failed to parse package.json at ${packageJsonPath}: ${String(error)}`,
          );
        }
      }
      // Move up one directory level
      const parentDir = dirname(dir);
      if (dir === parentDir) {
        // We've reached the root directory, so break out of the loop
        break;
      }
      dir = parentDir;
    }
  });

  return packageJsonDirs;
}

/**
 * Install dependencies in the package.json directories
 * @param packageJsonDirs Set of directories containing package.json files
 */
export function installDependencies(packageJsonDirs: Set<string>): void {
  // Sanity check that we found at least one package.json directory
  if (packageJsonDirs.size === 0) {
    console.warn(
      'WARN: failed to detect any package.json directories for cds compiler installation.',
    );
    return;
  }

  packageJsonDirs.forEach(dir => {
    console.log(`Installing node dependencies from ${dir}/package.json ...`);
    try {
      execFileSync('npm', ['install', '--quiet', '--no-audit', '--no-fund'], {
        cwd: dir,
        stdio: 'inherit',
      });

      // Order is important here. Install dependencies from package.json in the directory,
      // then install the CDS development kit (`@sap/cds-dk`) in the directory.
      console.log(`Installing '@sap/cds-dk' into ${dir} to enable CDS compilation ...`);
      execFileSync(
        'npm',
        ['install', '--quiet', '--no-audit', '--no-fund', '--no-save', '@sap/cds-dk'],
        { cwd: dir, stdio: 'inherit' },
      );
    } catch (error) {
      console.error(`Failed to install dependencies in ${dir}: ${String(error)}`);
    }
  });
}
