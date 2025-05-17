import * as childProcess from 'child_process';
import * as path from 'path';

import { determineCdsCommand, compileCdsToJson } from '../../../../src/cds/compiler/functions';
import * as filesystem from '../../../../src/filesystem';

// Mock dependencies
jest.mock('child_process', () => ({
  execFileSync: jest.fn(),
  spawnSync: jest.fn(),
}));

jest.mock('path', () => ({
  ...jest.requireActual('path'),
  resolve: jest.fn(),
  join: jest.fn(),
  delimiter: jest.requireActual('path').delimiter,
}));

jest.mock('../../../../src/filesystem', () => ({
  fileExists: jest.fn(),
  dirExists: jest.fn(),
  recursivelyRenameJsonFiles: jest.fn(),
}));

describe('cds compiler functions', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('determineCdsCommand', () => {
    it('should return "cds" when cds command is available', () => {
      // Mock successful execution of "cds --version"
      (childProcess.execFileSync as jest.Mock).mockImplementation(() => Buffer.from('4.6.0'));

      // Execute
      const result = determineCdsCommand();

      // Verify
      expect(result).toBe('cds');
      expect(childProcess.execFileSync).toHaveBeenCalledWith('cds', ['--version'], {
        stdio: 'ignore',
      });
    });

    it('should return "npx -y --package @sap/cds-dk cds" when cds command is not available', () => {
      // Mock failed execution of "cds --version"
      (childProcess.execFileSync as jest.Mock).mockImplementation(() => {
        throw new Error('Command not found');
      });

      // Execute
      const result = determineCdsCommand();

      // Verify
      expect(result).toBe('npx -y --package @sap/cds-dk cds');
      expect(childProcess.execFileSync).toHaveBeenCalledWith('cds', ['--version'], {
        stdio: 'ignore',
      });
    });
  });

  describe('compileCdsToJson', () => {
    beforeEach(() => {
      // Mock path functions
      (path.resolve as jest.Mock).mockImplementation(p => `/resolved/${p}`);
      (path.join as jest.Mock).mockImplementation((...parts) => parts.join('/'));

      // Default mocks for filesystem functions
      (filesystem.fileExists as jest.Mock).mockReturnValue(true);
      (filesystem.dirExists as jest.Mock).mockReturnValue(false);
    });

    it('should return failure when input CDS file does not exist', () => {
      // Setup
      (filesystem.fileExists as jest.Mock).mockReturnValueOnce(false);

      // Execute
      const result = compileCdsToJson('test.cds', '/source/root', 'cds');

      // Verify
      expect(result.success).toBe(false);
      expect(result.message).toContain('does not exist');
      expect(filesystem.fileExists).toHaveBeenCalledWith('/resolved/test.cds');
    });

    it('should successfully compile CDS to JSON file', () => {
      // Setup
      const resolvedCdsPath = '/resolved/test.cds';
      const cdsJsonOutPath = `${resolvedCdsPath}.json`;

      // Mock successful spawn process
      (childProcess.spawnSync as jest.Mock).mockReturnValue({
        status: 0,
        stdout: Buffer.from('Compilation successful'),
        stderr: Buffer.from(''),
      });

      // Execute
      const result = compileCdsToJson('test.cds', '/source/root', 'cds');

      // Verify
      expect(result.success).toBe(true);
      expect(result.outputPath).toBe(cdsJsonOutPath);
      expect(childProcess.spawnSync).toHaveBeenCalledWith(
        'cds',
        expect.arrayContaining(['compile', resolvedCdsPath, '--to', 'json']),
        expect.any(Object),
      );
    });

    it('should handle compilation errors', () => {
      // Setup
      // Mock failed spawn process
      (childProcess.spawnSync as jest.Mock).mockReturnValue({
        status: 1,
        stdout: Buffer.from(''),
        stderr: Buffer.from('Compilation failed with error'),
      });

      // Execute
      const result = compileCdsToJson('test.cds', '/source/root', 'cds');

      // Verify
      expect(result.success).toBe(false);
      expect(result.message).toContain('Could not compile');
      expect(result.message).toContain('Compilation failed with error');
    });

    it('should handle directory output and rename files', () => {
      // Setup
      const resolvedCdsPath = '/resolved/test.cds';
      const cdsJsonOutPath = `${resolvedCdsPath}.json`;

      // Mock successful spawn process
      (childProcess.spawnSync as jest.Mock).mockReturnValue({
        status: 0,
        stdout: Buffer.from('Compilation successful'),
        stderr: Buffer.from(''),
      });

      // Mock directory output instead of file
      (filesystem.fileExists as jest.Mock).mockImplementation(path => {
        if (path === resolvedCdsPath) return true;
        if (path === cdsJsonOutPath) return false;
        return true;
      });
      (filesystem.dirExists as jest.Mock).mockImplementation(path => {
        return path === cdsJsonOutPath;
      });

      // Execute
      const result = compileCdsToJson('test.cds', '/source/root', 'cds');

      // Verify
      expect(result.success).toBe(true);
      expect(result.outputPath).toBe(cdsJsonOutPath);
      expect(filesystem.recursivelyRenameJsonFiles).toHaveBeenCalledWith(cdsJsonOutPath);
    });

    it('should use cache directory when provided', () => {
      // Setup
      const cacheDir = '/cache/dir';
      const nodePath = '/cache/dir/node_modules';
      const binPath = '/cache/dir/node_modules/.bin';

      // Mock successful spawn process
      (childProcess.spawnSync as jest.Mock).mockReturnValue({
        status: 0,
        stdout: Buffer.from(''),
        stderr: Buffer.from(''),
      });

      // Execute
      compileCdsToJson('test.cds', '/source/root', 'cds', cacheDir);

      // Verify
      expect(childProcess.spawnSync).toHaveBeenCalledWith(
        'cds',
        expect.any(Array),
        expect.objectContaining({
          env: expect.objectContaining({
            NODE_PATH: expect.stringContaining(nodePath),
            PATH: expect.stringContaining(binPath),
          }),
        }),
      );
    });
  });
});
