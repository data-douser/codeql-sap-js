import * as childProcess from 'child_process';
import * as fs from 'fs';
import * as path from 'path';

import { CdsDependencyGraph, EnhancedCdsProject } from '../../../src/cds/parser/types';
import { installDependencies } from '../../../src/packageManager';

// Mock dependencies
jest.mock('fs', () => ({
  existsSync: jest.fn(),
  readFileSync: jest.fn(),
  mkdirSync: jest.fn(),
  writeFileSync: jest.fn(),
}));

jest.mock('path', () => ({
  ...jest.requireActual('path'),
  dirname: jest.fn(),
  join: jest.fn((...paths) => paths.join('/')),
  resolve: jest.fn((...paths) => paths.join('/')),
}));

jest.mock('child_process', () => ({
  execFileSync: jest.fn(),
  execSync: jest.fn(),
}));

jest.mock('../../../src/diagnostics', () => ({
  addDependencyDiagnostic: jest.fn(),
  addPackageJsonParsingDiagnostic: jest.fn(),
  DiagnosticSeverity: {
    Warning: 'warning',
    Error: 'error',
  },
}));

jest.mock('../../../src/logging', () => ({
  cdsExtractorLog: jest.fn(),
}));

// Mock the version resolver
jest.mock('../../../src/packageManager/versionResolver', () => ({
  resolveCdsVersions: jest.fn(),
}));

describe('installer', () => {
  // Helper function to create a minimal mock dependency graph
  const createMockDependencyGraph = (
    projects: Array<{
      projectDir: string;
      packageJson?: {
        name?: string;
        dependencies?: Record<string, string>;
        devDependencies?: Record<string, string>;
      };
    }>,
  ): CdsDependencyGraph => {
    const projectsMap = new Map<string, EnhancedCdsProject>();

    projects.forEach(({ projectDir, packageJson }) => {
      const enhancedProject: EnhancedCdsProject = {
        id: `project-${projectDir}`,
        projectDir,
        cdsFiles: [`${projectDir}/src/file.cds`],
        cdsFilesToCompile: [`${projectDir}/src/file.cds`],
        expectedOutputFiles: [`${projectDir}/src/file.json`],
        packageJson,
        status: 'discovered',
        compilationTasks: [],
        timestamps: {
          discovered: new Date(),
        },
      };
      projectsMap.set(projectDir, enhancedProject);
    });

    return {
      id: 'test-graph',
      sourceRootDir: '/source',
      scriptDir: '/script',
      projects: projectsMap,
      globalCacheDirectories: new Map(),
      fileCache: {
        fileContents: new Map(),
        packageJsonCache: new Map(),
        cdsParseCache: new Map(),
      },
      config: {
        maxRetryAttempts: 3,
        enableDetailedLogging: false,
        generateDebugOutput: false,
        compilationTimeoutMs: 30000,
      },
      debugInfo: {} as CdsDependencyGraph['debugInfo'],
      statusSummary: {
        totalProjects: projects.length,
        totalCdsFiles: projects.length,
        totalCompilationTasks: 0,
        successfulCompilations: 0,
        failedCompilations: 0,
        skippedCompilations: 0,
        retriedCompilations: 0,
        jsonFilesGenerated: 0,
        overallSuccess: true,
        criticalErrors: [],
        warnings: [],
        performance: {
          totalDurationMs: 0,
          parsingDurationMs: 100,
          compilationDurationMs: 0,
          extractionDurationMs: 0,
        },
      },
      errors: {
        critical: [],
        warnings: [],
      },
      currentPhase: 'parsing',
    };
  };

  beforeEach(() => {
    jest.clearAllMocks();

    // Setup default mocks
    (path.join as jest.Mock).mockImplementation((...paths: string[]) => paths.join('/'));
    (path.resolve as jest.Mock).mockImplementation((...paths: string[]) => paths.join('/'));
  });

  describe('installDependencies', () => {
    beforeEach(() => {
      // Mock file system operations
      (fs.existsSync as jest.Mock).mockReturnValue(false);
      (fs.mkdirSync as jest.Mock).mockReturnValue(undefined);
      (fs.writeFileSync as jest.Mock).mockReturnValue(undefined);
      (childProcess.execFileSync as jest.Mock).mockReturnValue('');

      // Mock version resolver
      const mockResolveCdsVersions = jest.mocked(
        jest.requireMock('../../../src/packageManager/versionResolver').resolveCdsVersions,
      );
      mockResolveCdsVersions.mockReturnValue({
        resolvedCdsVersion: '6.1.3',
        resolvedCdsDkVersion: '6.0.0',
        cdsExactMatch: true,
        cdsDkExactMatch: true,
      });
    });

    it('should install dependencies successfully', () => {
      const dependencyGraph = createMockDependencyGraph([
        {
          projectDir: '/project1',
          packageJson: {
            name: 'project1',
            dependencies: { '@sap/cds': '6.1.3' },
            devDependencies: { '@sap/cds-dk': '6.0.0' },
          },
        },
      ]);

      const result = installDependencies(dependencyGraph, '/source', '/codeql');

      expect(fs.mkdirSync).toHaveBeenCalledWith('/source/.cds-extractor-cache', {
        recursive: true,
      });
      expect(fs.writeFileSync).toHaveBeenCalled();
      expect(childProcess.execFileSync).toHaveBeenCalledWith(
        'npm',
        ['install', '--quiet', '--no-audit', '--no-fund'],
        expect.objectContaining({ cwd: expect.stringContaining('cds-') }),
      );
      expect(result.size).toBe(1);
    });

    it('should handle cache directory creation failure', () => {
      (fs.mkdirSync as jest.Mock).mockImplementation(() => {
        throw new Error('Permission denied');
      });

      const dependencyGraph = createMockDependencyGraph([
        {
          projectDir: '/project1',
          packageJson: { name: 'project1', dependencies: { '@sap/cds': '6.1.3' } },
        },
      ]);

      const result = installDependencies(dependencyGraph, '/source', '/codeql');

      // Should return empty map since cache creation failed
      expect(result.size).toBe(0);
    });

    it('should use existing cached dependencies', () => {
      // Mock that node_modules already exists - need to handle cache dir structure
      (fs.existsSync as jest.Mock).mockImplementation((path: string) => {
        // Return true for cache root directory
        if (path === '/source/.cds-extractor-cache') {
          return true;
        }
        // Return true for the specific cache directory (cds-<hash>)
        if (path.includes('.cds-extractor-cache/cds-') && !path.includes('node_modules')) {
          return true;
        }
        // Return true for the specific node_modules paths that the code checks
        if (path.includes('.cds-extractor-cache/cds-') && path.endsWith('node_modules/@sap/cds')) {
          return true;
        }
        if (
          path.includes('.cds-extractor-cache/cds-') &&
          path.endsWith('node_modules/@sap/cds-dk')
        ) {
          return true;
        }
        return false;
      });

      const dependencyGraph = createMockDependencyGraph([
        {
          projectDir: '/project1',
          packageJson: {
            name: 'project1',
            dependencies: { '@sap/cds': '6.1.3' },
            devDependencies: { '@sap/cds-dk': '6.0.0' },
          },
        },
      ]);

      const result = installDependencies(dependencyGraph, '/source', '/codeql');

      // Should not call npm install since cache exists
      expect(childProcess.execFileSync).not.toHaveBeenCalledWith(
        'npm',
        ['install', '--quiet', '--no-audit', '--no-fund'],
        expect.any(Object),
      );
      expect(result.size).toBe(1);
    });

    it('should handle npm install failures gracefully', () => {
      (childProcess.execFileSync as jest.Mock).mockImplementation((command: string) => {
        if (command === 'npm') {
          throw new Error('npm install failed');
        }
        return '';
      });

      const dependencyGraph = createMockDependencyGraph([
        {
          projectDir: '/project1',
          packageJson: {
            name: 'project1',
            dependencies: { '@sap/cds': '6.1.3' },
            devDependencies: { '@sap/cds-dk': '6.0.0' },
          },
        },
      ]);

      const result = installDependencies(dependencyGraph, '/source', '/codeql');

      // Should skip failed combinations
      expect(result.size).toBe(0);
    });

    it('should handle empty dependency graph', () => {
      const dependencyGraph = createMockDependencyGraph([]);
      const result = installDependencies(dependencyGraph, '/source', '/codeql');

      expect(result.size).toBe(0);
    });
  });
});
