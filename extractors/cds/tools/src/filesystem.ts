import { existsSync, readdirSync, readFileSync, renameSync, statSync } from 'fs';
import { format, join, parse } from 'path';

/**
 * Check if a file exists and can be read
 * @param filePath Path to the file to check
 * @returns True if the file exists and can be read, false otherwise
 */
export function fileExists(filePath: string): boolean {
  return existsSync(filePath) && statSync(filePath).isFile();
}

/**
 * Check if a directory exists
 * @param dirPath Path to the directory to check
 * @returns True if the directory exists, false otherwise
 */
export function dirExists(dirPath: string): boolean {
  return existsSync(dirPath) && statSync(dirPath).isDirectory();
}

/**
 * Read response file contents and split into lines
 * @param responseFile Path to the response file
 * @returns Array of file paths from the response file
 */
export function readResponseFile(responseFile: string): string[] {
  try {
    // Read the response file and split it into lines, removing empty lines
    const responseFiles = readFileSync(responseFile, 'utf-8').split('\n').filter(Boolean);
    return responseFiles;
  } catch (err) {
    throw new Error(
      `Response file '${responseFile}' could not be read due to an error: ${String(err)}`,
    );
  }
}

/**
 * Recursively renames all .json files to .cds.json in the given directory and
 * its subdirectories, except for those that already have .cds.json extension.
 *
 * @param {string} dirPath - The directory path to start recursion from
 */
export function recursivelyRenameJsonFiles(dirPath: string): void {
  // Make sure the directory exists
  if (!dirExists(dirPath)) {
    console.log(`Directory not found or not a directory: ${dirPath}`);
    return;
  }

  console.log(`Processing JSON files in output directory: ${dirPath}`);

  // Get all entries in the directory
  const entries = readdirSync(dirPath, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = join(dirPath, entry.name);

    if (entry.isDirectory()) {
      // Recursively process subdirectories
      recursivelyRenameJsonFiles(fullPath);
    } else if (
      entry.isFile() &&
      entry.name.endsWith('.json') &&
      !entry.name.endsWith('.cds.json')
    ) {
      // Rename .json files to .cds.json
      const newPath = format({ ...parse(fullPath), base: '', ext: '.cds.json' });
      renameSync(fullPath, newPath);
      console.log(`Renamed CDS output file from ${fullPath} to ${newPath}`);
    }
  }
}
