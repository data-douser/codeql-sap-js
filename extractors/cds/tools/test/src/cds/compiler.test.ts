import * as childProcess from 'child_process';

import { determineCdsCommand, compileCdsToJson } from '../../../src/cds/compiler';
import * as filesystem from '../../../src/filesystem';

// Mock dependencies
jest.mock('child_process', () => ({
  execFileSync: jest.fn(),
  spawnSync: jest.fn(),
}));

jest.mock('fs', () => ({
  existsSync: jest.fn(),
}));

jest.mock('../../../src/filesystem', () => ({
  fileExists: jest.fn(),
  dirExists: jest.fn(),
  recursivelyRenameJsonFiles: jest.fn(),
}));

describe('cdsCompiler', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('determineCdsCommand', () => {
    it('should return "cds" when cds command is available', () => {
      // Mock successful execution of "cds --version"
      (childProcess.execFileSync as jest.Mock).mockReturnValue(Buffer.from('4.6.0'));

      const result = determineCdsCommand();

      expect(result).toBe('cds');
      expect(childProcess.execFileSync).toHaveBeenCalledWith(
        'cds',
        ['--version'],
        expect.objectContaining({ stdio: 'ignore' }),
      );
    });

    it('should return "npx -y --package @sap/cds-dk cds" when cds command is not available', () => {
      // Mock error when executing "cds --version"
      (childProcess.execFileSync as jest.Mock).mockImplementation(() => {
        throw new Error('Command not found');
      });

      const result = determineCdsCommand();

      expect(result).toBe('npx -y --package @sap/cds-dk cds');
      expect(childProcess.execFileSync).toHaveBeenCalledWith(
        'cds',
        ['--version'],
        expect.objectContaining({ stdio: 'ignore' }),
      );
    });
  });

  describe('compileCdsToJson', () => {
    it('should successfully compile CDS file to JSON file', () => {
      const cdsFilePath = '/path/to/model.cds';
      const sourceRoot = '/path/to';
      const cdsCommand = 'cds';
      const expectedJsonPath = '/path/to/model.cds.json';

      // Mock filesystem.fileExists to return true for CDS file
      (filesystem.fileExists as jest.Mock).mockImplementation(path => path === cdsFilePath);

      // Mock successful compilation
      (childProcess.spawnSync as jest.Mock).mockReturnValue({
        status: 0,
        stderr: null,
        error: null,
      });

      // Mock that the output JSON file exists
      (filesystem.fileExists as jest.Mock).mockImplementation(
        path => path === cdsFilePath || path === expectedJsonPath,
      );

      // Mock that the output is not a directory
      (filesystem.dirExists as jest.Mock).mockReturnValue(false);

      const result = compileCdsToJson(cdsFilePath, sourceRoot, cdsCommand);

      expect(result).toEqual({
        success: true,
        outputPath: expectedJsonPath,
      });

      expect(childProcess.spawnSync).toHaveBeenCalledWith(
        cdsCommand,
        [
          'compile',
          cdsFilePath,
          '--to',
          'json',
          '--dest',
          expectedJsonPath,
          '--locations',
          '--log-level',
          'warn',
        ],
        expect.objectContaining({
          cwd: sourceRoot,
          shell: true,
          stdio: 'pipe',
        }),
      );
    });

    it('should handle CDS file that does not exist', () => {
      const cdsFilePath = '/path/to/nonexistent.cds';
      const sourceRoot = '/path/to';
      const cdsCommand = 'cds';

      // Mock filesystem.fileExists to return false for CDS file
      (filesystem.fileExists as jest.Mock).mockReturnValue(false);

      const result = compileCdsToJson(cdsFilePath, sourceRoot, cdsCommand);

      expect(result).toEqual({
        success: false,
        message: expect.stringContaining(`Expected CDS file '${cdsFilePath}' does not exist.`),
      });

      expect(childProcess.spawnSync).not.toHaveBeenCalled();
    });

    it('should handle compilation errors', () => {
      const cdsFilePath = '/path/to/model.cds';
      const sourceRoot = '/path/to';
      const cdsCommand = 'cds';

      // Mock filesystem.fileExists to return true for CDS file
      (filesystem.fileExists as jest.Mock).mockImplementation(path => path === cdsFilePath);

      // Mock compilation failure
      (childProcess.spawnSync as jest.Mock).mockReturnValue({
        status: 1,
        stderr: Buffer.from('Syntax error in CDS file'),
        error: null,
      });

      const result = compileCdsToJson(cdsFilePath, sourceRoot, cdsCommand);

      expect(result).toEqual({
        success: false,
        message: expect.stringContaining('Could not compile the file'),
      });
    });

    it('should handle directory output and rename files', () => {
      const cdsFilePath = '/path/to/model.cds';
      const sourceRoot = '/path/to';
      const cdsCommand = 'cds';
      const expectedJsonPath = '/path/to/model.cds.json';

      // Mock filesystem.fileExists to return true for CDS file
      (filesystem.fileExists as jest.Mock).mockImplementation(path => path === cdsFilePath);

      // Mock successful compilation
      (childProcess.spawnSync as jest.Mock).mockReturnValue({
        status: 0,
        stderr: null,
        error: null,
      });

      // Mock that the output is a directory
      (filesystem.fileExists as jest.Mock).mockImplementation(path => path === cdsFilePath);
      (filesystem.dirExists as jest.Mock).mockImplementation(path => path === expectedJsonPath);

      const result = compileCdsToJson(cdsFilePath, sourceRoot, cdsCommand);

      expect(result).toEqual({
        success: true,
        outputPath: expectedJsonPath,
      });

      // Check if recursivelyRenameJsonFiles was called
      expect(filesystem.recursivelyRenameJsonFiles).toHaveBeenCalledWith(expectedJsonPath);
    });
  });
});
