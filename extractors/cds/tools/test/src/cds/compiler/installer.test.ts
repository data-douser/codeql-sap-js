/** Tests for CDS compiler installer functionality */

import { execFileSync } from 'child_process';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { join } from 'path';

import {
  installFullDependencies,
  needsFullDependencyInstallation,
  createRetryCacheDirectory,
} from '../../../../src/cds/compiler/installer';
import type { CdsProject } from '../../../../src/cds/parser/types';
import { cdsExtractorLog } from '../../../../src/logging';

// Mock all external dependencies
jest.mock('child_process');
jest.mock('fs');
jest.mock('../../../../src/logging');

const mockExecFileSync = execFileSync as jest.MockedFunction<typeof execFileSync>;
const mockExistsSync = existsSync as jest.MockedFunction<typeof existsSync>;
const mockMkdirSync = mkdirSync as jest.MockedFunction<typeof mkdirSync>;
const mockReadFileSync = readFileSync as jest.MockedFunction<typeof readFileSync>;
const mockWriteFileSync = writeFileSync as jest.MockedFunction<typeof writeFileSync>;
const mockCdsExtractorLog = cdsExtractorLog as jest.MockedFunction<typeof cdsExtractorLog>;

describe('CDS Compiler Installer', () => {
  const mockSourceRoot = '/test/source';
  const mockCodeqlExePath = '/test/codeql';

  beforeEach(() => {
    jest.clearAllMocks();
    // Mock Date.now to return a consistent timestamp for testing
    jest.spyOn(Date, 'now').mockReturnValue(1640995200000);
    // Mock process.hrtime.bigint for performance timing
    jest.spyOn(process.hrtime, 'bigint').mockReturnValue(BigInt(1640995200000000000));
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  // Helper to create minimal valid CdsProject
  const createMockProject = (overrides: Partial<CdsProject> = {}): CdsProject => ({
    id: 'test-project-id',
    projectDir: 'test-project',
    cdsFiles: [],
    compilationTasks: [],
    status: 'discovered' as const,
    timestamps: { discovered: new Date() },
    cdsFilesToCompile: [],
    expectedOutputFiles: [],
    packageJson: {
      name: 'test-package',
      version: '1.0.0',
      dependencies: { dep1: '^1.0.0' },
      devDependencies: { 'dev-dep1': '^2.0.0' },
    },
    ...overrides,
  });

  describe('installFullDependencies', () => {
    it('should successfully install dependencies and return success result', () => {
      const project = createMockProject();
      const expectedCacheDir =
        '/test/source/.cds-extractor-cache/retry-dGVzdC1wcm9qZWN0-1640995200000';

      mockExistsSync.mockReturnValue(false);
      mockMkdirSync.mockReturnValue(undefined);
      mockWriteFileSync.mockReturnValue(undefined);
      mockExecFileSync.mockReturnValue(Buffer.from(''));

      const result = installFullDependencies(project, mockSourceRoot, mockCodeqlExePath);

      expect(result.success).toBe(true);
      expect(result.retryCacheDir).toBe(expectedCacheDir);
      expect(result.error).toBeUndefined();
      expect(result.warnings).toEqual([]);
      expect(result.timedOut).toBe(false);
      expect(result.durationMs).toBeGreaterThanOrEqual(0);

      expect(mockExecFileSync).toHaveBeenCalledWith(
        'npm',
        ['install', '--quiet', '--no-audit', '--no-fund'],
        {
          cwd: expectedCacheDir,
          stdio: 'inherit',
          timeout: 120000,
        },
      );
    });

    it('should handle npm install timeout gracefully', () => {
      const project = createMockProject();
      mockExistsSync.mockReturnValue(false);
      mockMkdirSync.mockReturnValue(undefined);
      mockWriteFileSync.mockReturnValue(undefined);

      const timeoutError = new Error('Command timed out') as Error & { signal: string };
      timeoutError.signal = 'SIGTERM';
      mockExecFileSync.mockImplementation(() => {
        throw timeoutError;
      });

      const result = installFullDependencies(project, mockSourceRoot, mockCodeqlExePath);

      expect(result.success).toBe(false);
      expect(result.timedOut).toBe(true);
      expect(result.error).toBe('Dependency installation timed out');
      expect(result.warnings).toHaveLength(1);
      expect(result.warnings[0]).toContain('Dependency installation failed');
    });

    it('should handle package.json creation failure', () => {
      const project = createMockProject({ packageJson: undefined });
      mockExistsSync.mockReturnValue(false);

      const result = installFullDependencies(project, mockSourceRoot, mockCodeqlExePath);

      expect(result.success).toBe(false);
      expect(result.error).toBe('Failed to create package.json for retry');
    });

    it('should handle cache directory creation failure', () => {
      const project = createMockProject();
      mockExistsSync.mockReturnValue(false);
      mockMkdirSync.mockImplementation(() => {
        throw new Error('Permission denied');
      });

      const result = installFullDependencies(project, mockSourceRoot, mockCodeqlExePath);

      expect(result.success).toBe(false);
      expect(result.error).toContain('Failed to install full dependencies');
    });
  });

  describe('needsFullDependencyInstallation', () => {
    it('should return false if dependencies already installed', () => {
      const project = createMockProject({
        retryStatus: {
          fullDependenciesInstalled: true,
          tasksRequiringRetry: 0,
          tasksRetried: 0,
        },
      });

      const result = needsFullDependencyInstallation(project);
      expect(result).toBe(false);
    });

    it('should return false if project has no package.json', () => {
      const project = createMockProject({
        packageJson: undefined,
        compilationTasks: [
          {
            id: 'task1',
            status: 'failed' as const,
            retryInfo: { hasBeenRetried: false },
          } as Partial<CdsProject['compilationTasks'][0]>,
        ] as CdsProject['compilationTasks'],
      });

      const result = needsFullDependencyInstallation(project);
      expect(result).toBe(false);
    });

    it('should return true if project has failed tasks that have not been retried', () => {
      const project = createMockProject({
        compilationTasks: [
          {
            id: 'task1',
            status: 'failed' as const,
            retryInfo: { hasBeenRetried: false },
          } as Partial<CdsProject['compilationTasks'][0]>,
        ] as CdsProject['compilationTasks'],
      });

      const result = needsFullDependencyInstallation(project);
      expect(result).toBe(true);
    });
  });

  describe('createRetryCacheDirectory', () => {
    it('should create cache directory when it does not exist', () => {
      const project = createMockProject();
      mockExistsSync.mockReturnValue(false);
      mockMkdirSync.mockReturnValue(undefined);

      const result = createRetryCacheDirectory(project, mockSourceRoot);

      const expectedCacheRoot = join(mockSourceRoot, '.cds-extractor-cache');
      const expectedCacheDir = join(expectedCacheRoot, 'retry-dGVzdC1wcm9qZWN0-1640995200000');

      expect(result).toBe(expectedCacheDir);
      expect(mockMkdirSync).toHaveBeenCalledWith(expectedCacheRoot, { recursive: true });
      expect(mockMkdirSync).toHaveBeenCalledWith(expectedCacheDir, { recursive: true });
    });

    it('should generate unique directory names for different projects', () => {
      mockExistsSync.mockReturnValue(true);
      mockMkdirSync.mockReturnValue(undefined);

      const project1 = createMockProject({ projectDir: 'project-a' });
      const project2 = createMockProject({ projectDir: 'project-b' });

      const result1 = createRetryCacheDirectory(project1, mockSourceRoot);
      const result2 = createRetryCacheDirectory(project2, mockSourceRoot);

      expect(result1).not.toBe(result2);
      expect(result1).toContain('cHJvamVjdC1h'); // Base64 of 'project-a'
      expect(result2).toContain('cHJvamVjdC1i'); // Base64 of 'project-b'
    });
  });

  describe('package.json creation and file operations', () => {
    it('should create package.json with merged dependencies', () => {
      const project = createMockProject({
        packageJson: {
          name: 'test-package',
          version: '1.0.0',
          dependencies: { dep1: '^1.0.0' },
          devDependencies: { 'dev-dep1': '^2.0.0' },
          engines: { node: '>=16' },
        },
      });
      mockExistsSync.mockReturnValue(false);
      mockMkdirSync.mockReturnValue(undefined);
      mockWriteFileSync.mockReturnValue(undefined);
      mockExecFileSync.mockReturnValue(Buffer.from(''));

      installFullDependencies(project, mockSourceRoot, mockCodeqlExePath);

      expect(mockWriteFileSync).toHaveBeenCalledWith(
        expect.stringContaining('package.json'),
        expect.stringContaining('"name": "test-package-retry"'),
      );
    });

    it('should copy package-lock.json when it exists', () => {
      const project = createMockProject();
      const mockLockContent = { name: 'test-package', lockfileVersion: 2 };

      mockExistsSync.mockImplementation(path => {
        return (
          String(path).includes('package-lock.json') ||
          !String(path).includes('.cds-extractor-cache')
        );
      });
      mockMkdirSync.mockReturnValue(undefined);
      mockWriteFileSync.mockReturnValue(undefined);
      mockReadFileSync.mockReturnValue(JSON.stringify(mockLockContent));
      mockExecFileSync.mockReturnValue(Buffer.from(''));

      installFullDependencies(project, mockSourceRoot, mockCodeqlExePath);

      expect(mockWriteFileSync).toHaveBeenCalledWith(
        expect.stringContaining('package-lock.json'),
        JSON.stringify(mockLockContent, null, 2),
      );
    });

    it('should handle package-lock.json read failure gracefully', () => {
      const project = createMockProject();

      mockExistsSync.mockImplementation(path => {
        return (
          String(path).includes('package-lock.json') ||
          !String(path).includes('.cds-extractor-cache')
        );
      });
      mockMkdirSync.mockReturnValue(undefined);
      mockWriteFileSync.mockReturnValue(undefined);
      mockReadFileSync.mockImplementation(() => {
        throw new Error('File read error');
      });
      mockExecFileSync.mockReturnValue(Buffer.from(''));

      installFullDependencies(project, mockSourceRoot, mockCodeqlExePath);

      expect(mockCdsExtractorLog).toHaveBeenCalledWith(
        'warn',
        expect.stringContaining('Failed to read package-lock.json'),
      );
    });

    it('should handle file write errors', () => {
      const project = createMockProject();
      mockExistsSync.mockReturnValue(false);
      mockMkdirSync.mockReturnValue(undefined);
      mockWriteFileSync.mockImplementation(() => {
        throw new Error('Write permission denied');
      });

      const result = installFullDependencies(project, mockSourceRoot, mockCodeqlExePath);

      expect(result.success).toBe(false);
      expect(result.error).toBe('Failed to create package.json for retry');
    });
  });
});
