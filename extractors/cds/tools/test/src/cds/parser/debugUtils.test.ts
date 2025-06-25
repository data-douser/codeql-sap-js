import { mkdtemp, rm } from 'fs/promises';
import { tmpdir } from 'os';
import { join } from 'path';

import { describe, it, expect, beforeEach, afterEach } from '@jest/globals';

import {
  handleDebugParserMode,
  handleDebugCompilerMode,
  isDebugMode,
  isDebugParserMode,
  isDebugCompilerMode,
} from '../../../../src/cds/parser/debugUtils';
import { CdsDependencyGraph } from '../../../../src/cds/parser/types';

describe('debugUtils', () => {
  let tempDir: string;

  beforeEach(async () => {
    tempDir = await mkdtemp(join(tmpdir(), 'cds-debug-utils-test-'));
  });

  afterEach(async () => {
    await rm(tempDir, { recursive: true, force: true });
  });

  describe('run mode detection functions', () => {
    it('should detect debug modes correctly', () => {
      expect(isDebugMode('debug-parser')).toBe(true);
      expect(isDebugMode('debug-compiler')).toBe(true);
      expect(isDebugMode('index-files')).toBe(false);
      expect(isDebugMode('autobuild')).toBe(false);
    });

    it('should detect debug-parser mode specifically', () => {
      expect(isDebugParserMode('debug-parser')).toBe(true);
      expect(isDebugParserMode('debug-compiler')).toBe(false);
      expect(isDebugParserMode('index-files')).toBe(false);
    });

    it('should detect debug-compiler mode specifically', () => {
      expect(isDebugCompilerMode('debug-compiler')).toBe(true);
      expect(isDebugCompilerMode('debug-parser')).toBe(false);
      expect(isDebugCompilerMode('index-files')).toBe(false);
    });
  });

  describe('handleDebugParserMode', () => {
    it('should return true when projects are found', () => {
      const mockDependencyGraph: CdsDependencyGraph = {
        id: 'test-graph',
        sourceRootDir: tempDir,
        scriptDir: tempDir,
        projects: new Map([
          [
            'test-project',
            {
              id: 'test-project',
              projectDir: 'test-project',
              cdsFiles: ['test.cds'],
              cdsFilesToCompile: ['test.cds'],
              expectedOutputFiles: [],
              packageJson: undefined,
              dependencies: [],
              imports: new Map(),
              enhancedCompilationConfig: undefined,
              compilationTasks: [],
              parserDebugInfo: {
                dependenciesResolved: [],
                importErrors: [],
                parseErrors: new Map(),
              },
              status: 'discovered',
              timestamps: {
                discovered: new Date(),
              },
            },
          ],
        ]),
        globalCacheDirectories: new Map(),
        debugInfo: {
          extractor: {
            runMode: 'debug-parser',
            sourceRootDir: tempDir,
            scriptDir: tempDir,
            startTime: new Date(),
            environment: {
              nodeVersion: process.version,
              platform: process.platform,
              cwd: process.cwd(),
              argv: process.argv,
            },
          },
          parser: {
            projectsDetected: 1,
            cdsFilesFound: 1,
            dependencyResolutionSuccess: true,
            parsingErrors: [],
            parsingWarnings: [],
          },
          compiler: {
            availableCommands: [],
            selectedCommand: '',
            cacheDirectories: [],
            cacheInitialized: false,
          },
        },
        currentPhase: 'parsing',
        statusSummary: {
          overallSuccess: false,
          totalProjects: 1,
          totalCdsFiles: 1,
          totalCompilationTasks: 0,
          successfulCompilations: 0,
          failedCompilations: 0,
          skippedCompilations: 0,
          retriedCompilations: 0,
          jsonFilesGenerated: 0,
          criticalErrors: [],
          warnings: [],
          performance: {
            totalDurationMs: 0,
            parsingDurationMs: 0,
            compilationDurationMs: 0,
            extractionDurationMs: 0,
          },
        },
        fileCache: {
          fileContents: new Map(),
          packageJsonCache: new Map(),
          cdsParseCache: new Map(),
        },
        config: {
          maxRetryAttempts: 3,
          enableDetailedLogging: true,
          generateDebugOutput: true,
          compilationTimeoutMs: 30000,
        },
        errors: {
          critical: [],
          warnings: [],
        },
      };

      const result = handleDebugParserMode(mockDependencyGraph, tempDir, tempDir);
      expect(result).toBe(true);
    });

    it('should return false when no projects are found', () => {
      const mockDependencyGraph: CdsDependencyGraph = {
        id: 'test-graph',
        sourceRootDir: tempDir,
        scriptDir: tempDir,
        projects: new Map(),
        globalCacheDirectories: new Map(),
        debugInfo: {
          extractor: {
            runMode: 'debug-parser',
            sourceRootDir: tempDir,
            scriptDir: tempDir,
            startTime: new Date(),
            environment: {
              nodeVersion: process.version,
              platform: process.platform,
              cwd: process.cwd(),
              argv: process.argv,
            },
          },
          parser: {
            projectsDetected: 0,
            cdsFilesFound: 0,
            dependencyResolutionSuccess: true,
            parsingErrors: [],
            parsingWarnings: [],
          },
          compiler: {
            availableCommands: [],
            selectedCommand: '',
            cacheDirectories: [],
            cacheInitialized: false,
          },
        },
        currentPhase: 'parsing',
        statusSummary: {
          overallSuccess: false,
          totalProjects: 0,
          totalCdsFiles: 0,
          totalCompilationTasks: 0,
          successfulCompilations: 0,
          failedCompilations: 0,
          skippedCompilations: 0,
          retriedCompilations: 0,
          jsonFilesGenerated: 0,
          criticalErrors: [],
          warnings: [],
          performance: {
            totalDurationMs: 0,
            parsingDurationMs: 0,
            compilationDurationMs: 0,
            extractionDurationMs: 0,
          },
        },
        fileCache: {
          fileContents: new Map(),
          packageJsonCache: new Map(),
          cdsParseCache: new Map(),
        },
        config: {
          maxRetryAttempts: 3,
          enableDetailedLogging: true,
          generateDebugOutput: true,
          compilationTimeoutMs: 30000,
        },
        errors: {
          critical: [],
          warnings: [],
        },
      };

      const result = handleDebugParserMode(mockDependencyGraph, tempDir, tempDir);
      expect(result).toBe(false);
    });
  });

  describe('handleDebugCompilerMode', () => {
    it('should return true when compilation is successful', () => {
      const mockDependencyGraph: CdsDependencyGraph = {
        id: 'test-graph',
        sourceRootDir: tempDir,
        scriptDir: tempDir,
        projects: new Map(),
        globalCacheDirectories: new Map(),
        debugInfo: {
          extractor: {
            runMode: 'debug-compiler',
            sourceRootDir: tempDir,
            scriptDir: tempDir,
            startTime: new Date(),
            environment: {
              nodeVersion: process.version,
              platform: process.platform,
              cwd: process.cwd(),
              argv: process.argv,
            },
          },
          parser: {
            projectsDetected: 1,
            cdsFilesFound: 1,
            dependencyResolutionSuccess: true,
            parsingErrors: [],
            parsingWarnings: [],
          },
          compiler: {
            availableCommands: [],
            selectedCommand: '',
            cacheDirectories: [],
            cacheInitialized: false,
          },
        },
        currentPhase: 'compiling',
        statusSummary: {
          overallSuccess: true,
          totalProjects: 1,
          totalCdsFiles: 1,
          totalCompilationTasks: 1,
          successfulCompilations: 1,
          failedCompilations: 0,
          skippedCompilations: 0,
          retriedCompilations: 0,
          jsonFilesGenerated: 1,
          criticalErrors: [],
          warnings: [],
          performance: {
            totalDurationMs: 0,
            parsingDurationMs: 0,
            compilationDurationMs: 0,
            extractionDurationMs: 0,
          },
        },
        fileCache: {
          fileContents: new Map(),
          packageJsonCache: new Map(),
          cdsParseCache: new Map(),
        },
        config: {
          maxRetryAttempts: 3,
          enableDetailedLogging: true,
          generateDebugOutput: true,
          compilationTimeoutMs: 30000,
        },
        errors: {
          critical: [],
          warnings: [],
        },
      };

      const result = handleDebugCompilerMode(mockDependencyGraph, 'debug-compiler');
      expect(result).toBe(true);
    });

    it('should return false when compilation fails', () => {
      const mockDependencyGraph: CdsDependencyGraph = {
        id: 'test-graph',
        sourceRootDir: tempDir,
        scriptDir: tempDir,
        projects: new Map(),
        globalCacheDirectories: new Map(),
        debugInfo: {
          extractor: {
            runMode: 'debug-compiler',
            sourceRootDir: tempDir,
            scriptDir: tempDir,
            startTime: new Date(),
            environment: {
              nodeVersion: process.version,
              platform: process.platform,
              cwd: process.cwd(),
              argv: process.argv,
            },
          },
          parser: {
            projectsDetected: 1,
            cdsFilesFound: 1,
            dependencyResolutionSuccess: true,
            parsingErrors: [],
            parsingWarnings: [],
          },
          compiler: {
            availableCommands: [],
            selectedCommand: '',
            cacheDirectories: [],
            cacheInitialized: false,
          },
        },
        currentPhase: 'compiling',
        statusSummary: {
          overallSuccess: false,
          totalProjects: 1,
          totalCdsFiles: 1,
          totalCompilationTasks: 1,
          successfulCompilations: 0,
          failedCompilations: 1,
          skippedCompilations: 0,
          retriedCompilations: 0,
          jsonFilesGenerated: 0,
          criticalErrors: [],
          warnings: [],
          performance: {
            totalDurationMs: 0,
            parsingDurationMs: 0,
            compilationDurationMs: 0,
            extractionDurationMs: 0,
          },
        },
        fileCache: {
          fileContents: new Map(),
          packageJsonCache: new Map(),
          cdsParseCache: new Map(),
        },
        config: {
          maxRetryAttempts: 3,
          enableDetailedLogging: true,
          generateDebugOutput: true,
          compilationTimeoutMs: 30000,
        },
        errors: {
          critical: [
            {
              phase: 'compilation',
              message: 'Test compilation error',
              timestamp: new Date(),
            },
          ],
          warnings: [],
        },
      };

      const result = handleDebugCompilerMode(mockDependencyGraph, 'debug-compiler');
      expect(result).toBe(false);
    });
  });
});
