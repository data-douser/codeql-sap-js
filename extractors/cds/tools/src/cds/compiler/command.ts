import { execFileSync } from 'child_process';
import { existsSync, readdirSync } from 'fs';
import { join, resolve } from 'path';

import type { ValidatedCdsCommand } from './types';
import { fileExists } from '../../filesystem';
import { cdsExtractorLog } from '../../logging';

/** Default timeout for command execution in milliseconds. **/
export const DEFAULT_COMMAND_TIMEOUT_MS = 10000;

/**
 * Cache for CDS command test results to avoid running the same CLI commands repeatedly.
 */
interface CdsCommandCache {
  /** Map of command strings to their test results */
  commandResults: Map<string, { works: boolean; version?: string; error?: string }>;
  /** Available cache directories discovered during testing */
  availableCacheDirs: string[];
  /** Global command test results */
  globalCommand?: string;
  /** Whether cache has been initialized */
  initialized: boolean;
}

// Global cache instance to share results across all calls
const cdsCommandCache: CdsCommandCache = {
  commandResults: new Map(),
  availableCacheDirs: [],
  initialized: false,
};

/**
 * Factory functions to create {@link ValidatedCdsCommand} instances.
 */
const createCdsCommands = {
  // Global CDS command
  cds: (): ValidatedCdsCommand => ({
    executable: 'cds',
    args: [],
    originalCommand: 'cds',
  }),
  // NPX with @sap/cds package
  npxCds: (): ValidatedCdsCommand => ({
    executable: 'npx',
    args: ['--yes', '--package', '@sap/cds', 'cds'],
    originalCommand: 'npx --yes --package @sap/cds cds',
  }),
  // NPX with @sap/cds-dk package
  npxCdsDk: (): ValidatedCdsCommand => ({
    executable: 'npx',
    args: ['--yes', '--package', '@sap/cds-dk', 'cds'],
    originalCommand: 'npx --yes --package @sap/cds-dk cds',
  }),
  // NPX with @sap/cds-dk package (alternative flag)
  npxCdsDkAlt: (): ValidatedCdsCommand => ({
    executable: 'npx',
    args: ['--yes', '@sap/cds-dk', 'cds'],
    originalCommand: 'npx --yes @sap/cds-dk cds',
  }),
};

/**
 * Creates a validated CDS command for an absolute path to a CDS executable.
 * @param absolutePath The absolute path to the CDS executable
 * @returns A {@link ValidatedCdsCommand} if the path exists and is valid, null otherwise
 */
function createCdsCommandForPath(absolutePath: string): ValidatedCdsCommand | null {
  try {
    const resolvedPath = resolve(absolutePath);
    if (resolvedPath && fileExists(resolvedPath)) {
      return {
        executable: resolvedPath,
        args: [],
        originalCommand: absolutePath,
      };
    }
  } catch {
    // Ignore path resolution errors
  }
  return null;
}

/**
 * Determine the `cds` command to use based on the environment and cache directory.
 *
 * This function uses a caching strategy to minimize repeated CLI command testing:
 * - Initializes a global cache on first call
 * - Tests global commands once and caches results
 * - Discovers all available cache directories upfront
 * - Reuses test results across multiple calls
 */
export function determineCdsCommand(cacheDir: string | undefined, sourceRoot: string): string {
  try {
    // Always use the efficient path - debug information is collected separately
    return getBestCdsCommand(cacheDir, sourceRoot);
  } catch (error) {
    const errorMessage = `Failed to determine CDS command: ${String(error)}`;
    cdsExtractorLog('error', errorMessage);
    throw new Error(errorMessage);
  }
}

/**
 * Discover all available cache directories in the source tree
 * @param sourceRoot The source root directory
 * @returns Array of cache directory paths
 */
function discoverAvailableCacheDirs(sourceRoot: string): string[] {
  if (cdsCommandCache.availableCacheDirs.length > 0) {
    return cdsCommandCache.availableCacheDirs;
  }

  const cacheRootDir = join(sourceRoot, '.cds-extractor-cache');
  const availableDirs: string[] = [];

  try {
    if (existsSync(cacheRootDir)) {
      const entries = readdirSync(cacheRootDir, { withFileTypes: true });
      for (const entry of entries) {
        if (entry.isDirectory() && entry.name.startsWith('cds-')) {
          const cacheDir = join(cacheRootDir, entry.name);
          const cdsBin = join(cacheDir, 'node_modules', '.bin', 'cds');
          if (fileExists(cdsBin)) {
            availableDirs.push(cacheDir);
          }
        }
      }
    }
  } catch (error) {
    cdsExtractorLog('debug', `Failed to discover cache directories: ${String(error)}`);
  }

  cdsCommandCache.availableCacheDirs = availableDirs;
  return availableDirs;
}

/**
 * Get the best CDS command for a specific cache directory
 * @param cacheDir Optional specific cache directory
 * @param sourceRoot The source root directory
 * @returns The best CDS command to use
 */
function getBestCdsCommand(cacheDir: string | undefined, sourceRoot: string): string {
  // Initialize cache if needed
  initializeCdsCommandCache(sourceRoot);

  // If a specific cache directory is provided and valid, prefer it
  if (cacheDir) {
    const localCdsBin = join(cacheDir, 'node_modules', '.bin', 'cds');
    const command = createCdsCommandForPath(localCdsBin);
    if (command) {
      const result = testCdsCommand(command, sourceRoot, true);
      if (result.works) {
        return localCdsBin;
      }
    }
  }

  // Try any available cache directories
  for (const availableCacheDir of cdsCommandCache.availableCacheDirs) {
    const localCdsBin = join(availableCacheDir, 'node_modules', '.bin', 'cds');
    const command = createCdsCommandForPath(localCdsBin);
    if (command) {
      const result = testCdsCommand(command, sourceRoot, true);
      if (result.works) {
        return localCdsBin;
      }
    }
  }

  // Fall back to global command
  if (cdsCommandCache.globalCommand) {
    return cdsCommandCache.globalCommand;
  }

  // Final fallback: test remaining npx options
  const fallbackCommands = [createCdsCommands.npxCds(), createCdsCommands.npxCdsDk()];

  for (const command of fallbackCommands) {
    const result = testCdsCommand(command, sourceRoot, true);
    if (result.works) {
      return command.originalCommand;
    }
  }

  // Return the default fallback even if it doesn't work, as tests expect this behavior
  return createCdsCommands.npxCdsDk().originalCommand;
}

/**
 * Initialize the CDS command cache by testing global commands
 * @param sourceRoot The source root directory
 */
function initializeCdsCommandCache(sourceRoot: string): void {
  if (cdsCommandCache.initialized) {
    return;
  }

  cdsExtractorLog('info', 'Initializing CDS command cache...');

  // Test global commands first (most commonly used)
  const globalCommands = [createCdsCommands.cds(), createCdsCommands.npxCdsDk()];

  for (const command of globalCommands) {
    const result = testCdsCommand(command, sourceRoot, true); // Silent testing
    if (result.works) {
      cdsCommandCache.globalCommand = command.originalCommand;
      cdsExtractorLog(
        'info',
        `Found working global CDS command: ${command.originalCommand} (v${result.version ?? 'unknown'})`,
      );
      break;
    }
  }

  // Discover available cache directories
  const cacheDirs = discoverAvailableCacheDirs(sourceRoot);
  if (cacheDirs.length > 0) {
    cdsExtractorLog(
      'info',
      `Discovered ${cacheDirs.length} CDS cache director${cacheDirs.length === 1 ? 'y' : 'ies'}`,
    );
  }

  cdsCommandCache.initialized = true;
}

/**
 * Reset the command cache - primarily for testing
 */
export function resetCdsCommandCache(): void {
  cdsCommandCache.commandResults.clear();
  cdsCommandCache.availableCacheDirs = [];
  cdsCommandCache.globalCommand = undefined;
  cdsCommandCache.initialized = false;
}

/**
 * Check if a CDS command is available and working.
 * @param validatedCommand The {@link ValidatedCdsCommand} instance for the command to test
 * @param sourceRoot The source root directory to use as cwd when testing the command
 * @param silent Whether to suppress logging of test failures
 * @returns Object with test result and version information
 */
function testCdsCommand(
  validatedCommand: ValidatedCdsCommand,
  sourceRoot: string,
  silent: boolean = false,
): { works: boolean; version?: string; error?: string } {
  const cacheKey = validatedCommand.originalCommand;

  // Check cache first
  const cachedResult = cdsCommandCache.commandResults.get(cacheKey);
  if (cachedResult) {
    return cachedResult;
  }

  try {
    // Run the validated `cds` command with `--version` to test if it works.
    const cleanEnv = {
      ...process.env,
      // Remove any CodeQL-specific environment variables that might interfere.
      CODEQL_EXTRACTOR_CDS_WIP_DATABASE: undefined,
      CODEQL_RUNNER: undefined,
    };

    const result = execFileSync(
      validatedCommand.executable,
      [...validatedCommand.args, '--version'],
      {
        encoding: 'utf8',
        stdio: 'pipe',
        timeout: DEFAULT_COMMAND_TIMEOUT_MS, // timeout after 10 seconds
        cwd: sourceRoot,
        env: cleanEnv,
      },
    ).toString();

    // Extract version from output (typically in format "@sap/cds-dk: 6.1.3" or just "6.1.3")
    const versionMatch = result.match(/(\d+\.\d+\.\d+)/);
    const version = versionMatch ? versionMatch[1] : undefined;

    const testResult = { works: true, version };
    cdsCommandCache.commandResults.set(cacheKey, testResult);
    return testResult;
  } catch (error) {
    const errorMessage = String(error);
    if (!silent) {
      cdsExtractorLog('debug', `CDS command test failed for '${cacheKey}': ${errorMessage}`);
    }

    const testResult = { works: false, error: errorMessage };
    cdsCommandCache.commandResults.set(cacheKey, testResult);
    return testResult;
  }
}
