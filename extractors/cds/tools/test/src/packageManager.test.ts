import * as childProcess from 'child_process';
import * as fs from 'fs';
import * as path from 'path';

import { findPackageJsonDirs, installDependencies } from '../../src/packageManager';

// Mock dependencies
jest.mock('fs', () => ({
  existsSync: jest.fn(),
  readFileSync: jest.fn(),
}));

jest.mock('path', () => ({
  ...jest.requireActual('path'),
  dirname: jest.fn(),
  join: jest.fn(),
  resolve: jest.fn((...paths) => paths.join('/')),
}));

jest.mock('child_process', () => ({
  execFileSync: jest.fn(),
}));

describe('packageManager', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('findPackageJsonDirs', () => {
    // Set up mocks for dirname to simulate directory structure
    let dirLevel = 2;

    beforeEach(() => {
      // Reset dirLevel before each test
      dirLevel = 2;

      // Mock implementation for dirname to simulate directory traversal
      (path.dirname as jest.Mock).mockImplementation(p => {
        // Return parent directory based on level
        if (dirLevel > 0) {
          dirLevel--;
          return `${p}_parent`;
        }
        return p; // Stop traversal by returning same path
      });

      // Mock join to concatenate paths
      (path.join as jest.Mock).mockImplementation((dir, file) => `${dir}/${file}`);
    });

    it('should find directories with package.json containing @sap/cds dependency', () => {
      // Sample CDS file paths
      const filePaths = ['/project/src/file1.cds', '/project/src/file2.cds'];

      // Mock existsSync to return true for package.json
      (fs.existsSync as jest.Mock).mockImplementation(() => true);

      // Mock readFileSync to return valid package.json content with @sap/cds dependency
      (fs.readFileSync as jest.Mock).mockReturnValue(
        JSON.stringify({
          name: 'test-project',
          dependencies: {
            '@sap/cds': '4.0.0',
          },
        }),
      );

      // We need to reset dirLevel between file paths to simulate correct directory traversal
      (path.dirname as jest.Mock).mockImplementation(p => {
        if (p === '/project/src/file1.cds') {
          return '/project/src/file1.cds_parent';
        } else if (p === '/project/src/file1.cds_parent') {
          return '/project/src/file1.cds_parent_parent';
        } else if (p === '/project/src/file2.cds') {
          return '/project/src/file2.cds_parent';
        } else if (p === '/project/src/file2.cds_parent') {
          return '/project/src/file2.cds_parent_parent';
        }
        return p; // Return the same path to stop traversal
      });

      const result = findPackageJsonDirs(filePaths);

      expect(result.size).toBe(2); // Should find package.json for both files
      expect(Array.from(result).sort()).toEqual(
        ['/project/src/file1.cds_parent', '/project/src/file2.cds_parent'].sort(),
      );
    });

    it('should not include directories without @sap/cds dependency', () => {
      const filePaths = ['/project/src/file.cds'];

      (fs.existsSync as jest.Mock).mockReturnValue(true);
      (fs.readFileSync as jest.Mock).mockReturnValue(
        JSON.stringify({
          name: 'test-project',
          dependencies: {
            'other-package': '1.0.0',
          },
        }),
      );

      const result = findPackageJsonDirs(filePaths);

      expect(result.size).toBe(0);
    });

    it('should handle JSON parse errors gracefully', () => {
      const filePaths = ['/project/src/file.cds'];

      (fs.existsSync as jest.Mock).mockReturnValue(true);
      (fs.readFileSync as jest.Mock).mockImplementation(() => {
        return 'invalid-json';
      });

      // Mock console.warn to avoid polluting test output
      const originalConsoleWarn = console.warn;
      console.warn = jest.fn();

      const result = findPackageJsonDirs(filePaths);

      expect(result.size).toBe(0);
      expect(console.warn).toHaveBeenCalled();

      // Restore console.warn
      console.warn = originalConsoleWarn;
    });
  });

  describe('installDependencies', () => {
    it('should install dependencies for each directory', () => {
      const packageJsonDirs = new Set(['/project1', '/project2']);

      installDependencies(packageJsonDirs);

      // Check npm install was called for each directory
      expect(childProcess.execFileSync).toHaveBeenCalledTimes(4); // 2 directories x 2 calls per directory

      // Check first npm install call for project1
      expect(childProcess.execFileSync).toHaveBeenNthCalledWith(
        1,
        'npm',
        ['install', '--quiet', '--no-audit', '--no-fund'],
        expect.objectContaining({ cwd: '/project1' }),
      );

      // Check @sap/cds-dk install call for project1
      expect(childProcess.execFileSync).toHaveBeenNthCalledWith(
        2,
        'npm',
        ['install', '--quiet', '--no-audit', '--no-fund', '--no-save', '@sap/cds-dk'],
        expect.objectContaining({ cwd: '/project1' }),
      );
    });

    it('should log warning when no directories are found', () => {
      const packageJsonDirs = new Set<string>();

      // Mock console.warn
      const originalConsoleWarn = console.warn;
      console.warn = jest.fn();

      installDependencies(packageJsonDirs);

      expect(childProcess.execFileSync).not.toHaveBeenCalled();
      expect(console.warn).toHaveBeenCalledWith(
        'WARN: failed to detect any package.json directories for cds compiler installation.',
      );

      // Restore console.warn
      console.warn = originalConsoleWarn;
    });
  });
});
