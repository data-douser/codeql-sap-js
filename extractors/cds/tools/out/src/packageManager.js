"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.findPackageJsonDirs = findPackageJsonDirs;
exports.installDependencies = installDependencies;
const child_process_1 = require("child_process");
const fs_1 = require("fs");
const path_1 = require("path");
const diagnostics_1 = require("./diagnostics");
/**
 * Find directories containing package.json with a `@sap/cds` dependency.
 * @param filePaths List of CDS file paths to check.
 * @param codeqlExePath Path to the CodeQL executable (optional).
 * @param sourceRoot The source root directory (optional) - Limits the search to
 * never go above this directory.
 * @returns Set of directories containing relevant package.json files.
 */
function findPackageJsonDirs(filePaths, codeqlExePath, sourceRoot) {
    const packageJsonDirs = new Set();
    const absoluteSourceRoot = sourceRoot ? (0, path_1.resolve)(sourceRoot) : undefined;
    filePaths.forEach(file => {
        let dir = (0, path_1.dirname)((0, path_1.resolve)(file));
        // Check current directory and parent directories for package.json with a
        // dependency on `@sap/cds`. Never look above the source root directory.
        while (true) {
            // Stop if we've reached or gone above the source root directory.
            if (absoluteSourceRoot && !dir.startsWith(absoluteSourceRoot)) {
                break;
            }
            const packageJsonPath = (0, path_1.join)(dir, 'package.json');
            if ((0, fs_1.existsSync)(packageJsonPath)) {
                try {
                    const rawData = (0, fs_1.readFileSync)(packageJsonPath, 'utf-8');
                    const packageJsonData = JSON.parse(rawData);
                    if (packageJsonData.name &&
                        packageJsonData.dependencies &&
                        typeof packageJsonData.dependencies === 'object' &&
                        Object.keys(packageJsonData.dependencies).includes('@sap/cds')) {
                        packageJsonDirs.add(dir);
                        break;
                    }
                }
                catch (error) {
                    const errorMessage = `Failed to parse package.json at ${packageJsonPath}: ${String(error)}`;
                    console.warn(`WARN: ${errorMessage}`);
                    if (codeqlExePath) {
                        (0, diagnostics_1.addPackageJsonParsingDiagnostic)(packageJsonPath, errorMessage, codeqlExePath);
                    }
                }
            }
            // Move up one directory level
            const parentDir = (0, path_1.dirname)(dir);
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
 * @param codeqlExePath Path to the CodeQL executable (optional)
 */
function installDependencies(packageJsonDirs, codeqlExePath) {
    // Sanity check that we found at least one package.json directory
    if (packageJsonDirs.size === 0) {
        console.warn('WARN: failed to detect any package.json directories for cds compiler installation.');
        return;
    }
    packageJsonDirs.forEach(dir => {
        console.log(`Installing node dependencies from ${dir}/package.json ...`);
        try {
            (0, child_process_1.execFileSync)('npm', ['install', '--quiet', '--no-audit', '--no-fund'], {
                cwd: dir,
                stdio: 'inherit',
            });
            // Order is important here. Install dependencies from package.json in the directory,
            // then install the CDS development kit (`@sap/cds-dk`) in the directory.
            console.log(`Installing '@sap/cds-dk' into ${dir} to enable CDS compilation ...`);
            (0, child_process_1.execFileSync)('npm', ['install', '--quiet', '--no-audit', '--no-fund', '--no-save', '@sap/cds-dk'], { cwd: dir, stdio: 'inherit' });
        }
        catch (err) {
            const errorMessage = `Failed to install dependencies in ${dir}: ${err instanceof Error ? err.message : String(err)}`;
            console.error(errorMessage);
            if (codeqlExePath) {
                const packageJsonPath = (0, path_1.join)(dir, 'package.json');
                (0, diagnostics_1.addDependencyDiagnostic)(packageJsonPath, errorMessage, codeqlExePath);
            }
        }
    });
}
//# sourceMappingURL=packageManager.js.map