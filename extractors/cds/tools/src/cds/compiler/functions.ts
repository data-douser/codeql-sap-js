import { execFileSync, spawnSync, SpawnSyncOptions } from 'child_process';
import { resolve, join, delimiter } from 'path';

import { CdsCompilationResult } from './types';
import { fileExists, dirExists, recursivelyRenameJsonFiles } from '../../filesystem';

/**
 * Determine the `cds` command to use based on the environment and cache directory.
 * @param cacheDir Optional path to a directory containing installed dependencies
 * @returns A string representing the CLI command to run to invoke the
 * CDS compiler.
 */
export function determineCdsCommand(cacheDir?: string): string {
  // If we have a cache directory, use the cds binary from there
  if (cacheDir) {
    const localCdsBin = join(cacheDir, 'node_modules', '.bin', 'cds');

    // Check if the local cds binary exists in the cache directory
    if (fileExists(localCdsBin)) {
      // We need to use node to execute the local bin directly to ensure correct resolution
      return `node "${localCdsBin}"`;
    }

    // If there's a cache directory but no local binary, use npx with NODE_PATH
    return `npx --no-install cds`;
  }

  // Default behavior when no cache directory is provided
  let cdsCommand = 'cds';
  try {
    execFileSync('cds', ['--version'], { stdio: 'ignore' });
  } catch {
    // If 'cds' command is not available, use npx to run it
    cdsCommand = 'npx -y --package @sap/cds-dk cds';
  }
  return cdsCommand;
}

/**
 * Get the CDS compiler version from a specific command or cache directory
 * @param cdsCommand The CDS command to use
 * @param cacheDir Optional path to a directory containing installed dependencies
 * @returns The CDS compiler version string, or undefined if it couldn't be determined
 */
export function getCdsVersion(cdsCommand: string, cacheDir?: string): string | undefined {
  try {
    // Set up environment vars if using a cache directory
    const spawnOptions: SpawnSyncOptions = {
      shell: true,
      stdio: 'pipe',
      env: { ...process.env },
    };

    // If a cache directory is provided, set NODE_PATH to use that cache
    if (cacheDir) {
      const nodePath = join(cacheDir, 'node_modules');

      // Set up environment to use the cached dependencies
      spawnOptions.env = {
        ...process.env,
        NODE_PATH: `${nodePath}${delimiter}${process.env.NODE_PATH ?? ''}`,
        PATH: `${join(nodePath, '.bin')}${delimiter}${process.env.PATH}`,
        npm_config_prefix: cacheDir,
      };
    }

    // Execute the CDS command with the --version flag
    const result = spawnSync(cdsCommand, ['--version'], spawnOptions);
    if (result.status === 0 && result.stdout) {
      const versionOutput = result.stdout.toString().trim();
      // Extract version number, which is typically in formats like "@sap/cds: 6.1.3" or similar
      const match = versionOutput.match(/@sap\/cds[^0-9]*([0-9]+\.[0-9]+\.[0-9]+)/);
      if (match?.[1]) {
        return match[1]; // Return just the version number
      }
      return versionOutput; // Return full output if we couldn't parse it
    }
    return undefined;
  } catch {
    return undefined;
  }
}

/**
 * Compile a CDS file to JSON
 * @param cdsFilePath Path to the CDS file
 * @param sourceRoot The source root directory
 * @param cdsCommand The CDS command to use
 * @param cacheDir Optional path to a directory containing installed dependencies
 * @returns Result of the compilation
 */
export function compileCdsToJson(
  cdsFilePath: string,
  sourceRoot: string,
  cdsCommand: string,
  cacheDir?: string,
): CdsCompilationResult {
  try {
    const resolvedCdsFilePath = resolve(cdsFilePath);
    if (!fileExists(resolvedCdsFilePath)) {
      throw new Error(`Expected CDS file '${resolvedCdsFilePath}' does not exist.`);
    }

    const cdsJsonOutPath = `${resolvedCdsFilePath}.json`;

    // Get and log the CDS version
    const cdsVersion = getCdsVersion(cdsCommand, cacheDir);
    const versionInfo = cdsVersion ? `with CDS v${cdsVersion}` : '';
    console.log(`Processing CDS file ${resolvedCdsFilePath} ${versionInfo}...`);

    // Prepare spawn options
    const spawnOptions: SpawnSyncOptions = {
      cwd: sourceRoot,
      shell: true,
      stdio: 'pipe',
      env: { ...process.env },
    };

    // If a cache directory is provided, set NODE_PATH to use that cache
    if (cacheDir) {
      const nodePath = join(cacheDir, 'node_modules');

      // Set up environment to use the cached dependencies
      spawnOptions.env = {
        ...process.env,
        NODE_PATH: `${nodePath}${delimiter}${process.env.NODE_PATH ?? ''}`,
        PATH: `${join(nodePath, '.bin')}${delimiter}${process.env.PATH}`,
        // Add NPM configuration to ensure dependencies are resolved from the cache directory
        npm_config_prefix: cacheDir,
      };

      console.log(`Using cached dependencies from: ${cacheDir}`);
    }

    const result = spawnSync(
      cdsCommand,
      [
        'compile',
        resolvedCdsFilePath,
        '--to',
        'json',
        '--dest',
        cdsJsonOutPath,
        '--locations',
        '--log-level',
        'warn',
      ],
      spawnOptions,
    );

    if (result.error) {
      throw new Error(`Error executing CDS compiler: ${result.error.message}`);
    }

    if (result.status !== 0) {
      throw new Error(
        `Could not compile the file ${resolvedCdsFilePath}.\nReported error(s):\n\`\`\`\n${
          result.stderr?.toString() || 'Unknown error'
        }\n\`\`\``,
      );
    }

    if (!fileExists(cdsJsonOutPath) && !dirExists(cdsJsonOutPath)) {
      throw new Error(
        `CDS source file '${resolvedCdsFilePath}' was not compiled to JSON. This is likely because the file does not exist or is not a valid CDS file.`,
      );
    }

    // Handle directory output if the CDS compiler generated a directory
    if (dirExists(cdsJsonOutPath)) {
      console.log(`CDS compiler generated JSON to output directory: ${cdsJsonOutPath}`);
      // Recursively rename all .json files to have a .cds.json extension
      recursivelyRenameJsonFiles(cdsJsonOutPath);
    } else {
      console.log(`CDS compiler generated JSON to file: ${cdsJsonOutPath}`);
    }

    return { success: true, outputPath: cdsJsonOutPath };
  } catch (error) {
    return { success: false, message: String(error) };
  }
}
