import { resolve } from 'path';

/**
 * Safely get a command-line parameter and properly resolve the path.
 * @param `args` - Command line arguments array.
 * @param `index` - Index of the argument to get.
 * @param `defaultValue` - Default value to return if argument is not present.
 * @returns The resolved argument value or the default value
 */
export function getArg(args: string[], index: number, defaultValue = ''): string {
  if (index < args.length) {
    // Handle the path resolution properly without unnecessary quoting
    return resolve(args[index]);
  }
  return defaultValue;
}

/**
 * Check if the script was invoked with the required arguments.
 * @param `args` Command line arguments to check.
 * @param `requiredCount` Number of required arguments.
 * @returns Boolean `true` if the script was invoked correctly, `false` otherwise.
 */
export function validateArguments(args: string[], requiredCount: number): boolean {
  if (args.length !== requiredCount) {
    // Extract the script name from the path properly
    const scriptPath = args[1] ?? '';
    const scriptName = scriptPath.split(/[/\\]/).pop() ?? 'index-files.js';
    console.warn(`Usage: node ${scriptName} <response-file> <source-root>`);
    return false;
  }
  return true;
}
