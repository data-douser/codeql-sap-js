import { execFileSync, spawnSync, SpawnSyncReturns } from 'child_process';
import { resolve } from 'path';

import { fileExists, dirExists, recursivelyRenameJsonFiles } from '../filesystem';

/**
 * Result of a CDS compilation
 */
export interface CdsCompilationResult {
  success: boolean;
  message?: string;
  outputPath?: string;
}

/**
 * Determine the `cds` command to use based on the environment.
 * @returns A string representing the CLI command to run to invoke the
 * CDS compiler.
 */
export function determineCdsCommand(): string {
  let cdsCommand = 'cds';
  // TODO : create a mapping of project sub-directories to the correct
  // cds command to use, which will also determine the version of the cds
  // compiler that will be used for compiling `.cds` files to `.cds.json`
  // files for that sub-directory / project.
  try {
    execFileSync('cds', ['--version'], { stdio: 'ignore' });
  } catch {
    // If 'cds' command is not available, use npx to run it
    cdsCommand = 'npx -y --package @sap/cds-dk cds';
  }
  return cdsCommand;
}

/**
 * Compile a CDS file to JSON
 * @param cdsFilePath Path to the CDS file
 * @param sourceRoot The source root directory
 * @param cdsCommand The CDS command to use
 * @returns Result of the compilation
 */
export function compileCdsToJson(
  cdsFilePath: string,
  sourceRoot: string,
  cdsCommand: string,
): CdsCompilationResult {
  try {
    const resolvedCdsFilePath = resolve(cdsFilePath);
    if (!fileExists(resolvedCdsFilePath)) {
      throw new Error(`Expected CDS file '${resolvedCdsFilePath}' does not exist.`);
    }

    const cdsJsonOutPath = `${resolvedCdsFilePath}.json`;
    console.log(`Processing CDS file ${resolvedCdsFilePath} to ${cdsJsonOutPath} ...`);

    const result: SpawnSyncReturns<Buffer> = spawnSync(
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
      { cwd: sourceRoot, shell: true, stdio: 'pipe' },
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
