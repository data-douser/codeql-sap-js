"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const childProcess = __importStar(require("child_process"));
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
const diagnostics_1 = require("../../src/diagnostics");
const packageManager_1 = require("../../src/packageManager");
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
jest.mock('../../src/diagnostics', () => ({
    addDependencyDiagnostic: jest.fn(),
    addPackageJsonParsingDiagnostic: jest.fn(),
}));
describe('packageManager', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });
    describe('findPackageJsonDirs', () => {
        // Helper functions to create cleaner tests
        const setupMockDirectoryStructure = (dirStructure) => {
            // Mock implementation for dirname to simulate specific directory structure
            path.dirname.mockImplementation((p) => {
                return dirStructure[p] || p; // Return mapped parent or same path
            });
            // Mock join to concatenate paths
            path.join.mockImplementation((dir, file) => `${dir}/${file}`);
            // Default resolve implementation
            path.resolve.mockImplementation((p) => p);
        };
        const setupMockPackageJson = (pathsAndContents) => {
            // Mock existsSync to check specific paths
            fs.existsSync.mockImplementation((path) => {
                return Object.prototype.hasOwnProperty.call(pathsAndContents, path);
            });
            // Mock readFileSync to return specified content
            fs.readFileSync.mockImplementation((path) => {
                if (pathsAndContents[path] === 'invalid-json') {
                    return 'invalid-json';
                }
                return JSON.stringify(pathsAndContents[path]);
            });
        };
        beforeEach(() => {
            // Mock join to concatenate paths by default
            path.join.mockImplementation((dir, file) => `${dir}/${file}`);
        });
        it('should find directories with package.json containing @sap/cds dependency', () => {
            // Setup directory structure
            const dirStructure = {
                '/project/src/file1.cds': '/project/src',
                '/project/src': '/project',
                '/project/src/file2.cds': '/project/src',
                '/project': '/',
            };
            setupMockDirectoryStructure(dirStructure);
            // Setup package.json files
            const packageJsonFiles = {
                '/project/package.json': {
                    name: 'test-project',
                    dependencies: {
                        '@sap/cds': '4.0.0',
                    },
                },
            };
            setupMockPackageJson(packageJsonFiles);
            const filePaths = ['/project/src/file1.cds', '/project/src/file2.cds'];
            const result = (0, packageManager_1.findPackageJsonDirs)(filePaths, '/mock/codeql');
            expect(result.size).toBe(1);
            expect(Array.from(result)[0]).toBe('/project');
        });
        it('should not include directories without @sap/cds dependency', () => {
            // Setup directory structure for various non-CDS package.json scenarios
            const dirStructure = {
                '/project-no-deps/file.cds': '/project-no-deps',
                '/project-empty-deps/file.cds': '/project-empty-deps',
                '/project-other-deps/file.cds': '/project-other-deps',
                '/project-dev-deps/file.cds': '/project-dev-deps',
                '/project-no-deps': '/',
                '/project-empty-deps': '/',
                '/project-other-deps': '/',
                '/project-dev-deps': '/',
            };
            setupMockDirectoryStructure(dirStructure);
            // Different package.json files without @sap/cds dependency
            const packageJsonFiles = {
                '/project-no-deps/package.json': {
                    name: 'test-project-no-deps',
                    // No dependencies at all
                },
                '/project-empty-deps/package.json': {
                    name: 'test-project-empty-deps',
                    dependencies: {},
                },
                '/project-other-deps/package.json': {
                    name: 'test-project-other-deps',
                    dependencies: {
                        'other-package': '1.0.0',
                    },
                },
                '/project-dev-deps/package.json': {
                    name: 'test-project-dev-deps',
                    // @sap/cds in devDependencies shouldn't count
                    devDependencies: {
                        '@sap/cds': '4.0.0',
                    },
                },
            };
            setupMockPackageJson(packageJsonFiles);
            const filePaths = [
                '/project-no-deps/file.cds',
                '/project-empty-deps/file.cds',
                '/project-other-deps/file.cds',
                '/project-dev-deps/file.cds',
            ];
            const result = (0, packageManager_1.findPackageJsonDirs)(filePaths, '/mock/codeql');
            expect(result.size).toBe(0);
        });
        it('should handle JSON parse errors gracefully', () => {
            const dirStructure = {
                '/project/file.cds': '/project',
                '/project': '/',
            };
            setupMockDirectoryStructure(dirStructure);
            const packageJsonFiles = {
                '/project/package.json': 'invalid-json',
            };
            setupMockPackageJson(packageJsonFiles);
            // Mock console.warn
            const originalConsoleWarn = console.warn;
            console.warn = jest.fn();
            const filePaths = ['/project/file.cds'];
            const mockCodeqlPath = '/mock/codeql';
            const result = (0, packageManager_1.findPackageJsonDirs)(filePaths, mockCodeqlPath);
            expect(result.size).toBe(0);
            expect(console.warn).toHaveBeenCalled();
            expect(diagnostics_1.addPackageJsonParsingDiagnostic).toHaveBeenCalledWith('/project/package.json', expect.any(String), mockCodeqlPath);
            // Restore console.warn
            console.warn = originalConsoleWarn;
        });
        it('should detect package.json in the source root directory', () => {
            // Setup directory structure with file in source root
            const dirStructure = {
                '/source-root/file.cds': '/source-root',
                '/source-root': '/',
            };
            setupMockDirectoryStructure(dirStructure);
            const packageJsonFiles = {
                '/source-root/package.json': {
                    name: 'root-project',
                    dependencies: {
                        '@sap/cds': '5.0.0',
                    },
                },
            };
            setupMockPackageJson(packageJsonFiles);
            const filePaths = ['/source-root/file.cds'];
            const result = (0, packageManager_1.findPackageJsonDirs)(filePaths, '/mock/codeql');
            expect(result.size).toBe(1);
            expect(Array.from(result)[0]).toBe('/source-root');
        });
        it('should not look for package.json above the source root directory', () => {
            // Setup directory structure with parent above source root
            const dirStructure = {
                '/source-root/subdir/file.cds': '/source-root/subdir',
                '/source-root/subdir': '/source-root',
                '/source-root': '/',
            };
            setupMockDirectoryStructure(dirStructure);
            // Package.json in source root and above it
            const packageJsonFiles = {
                '/source-root/package.json': {
                    name: 'root-project',
                    dependencies: {
                        '@sap/cds': '5.0.0',
                    },
                },
                '/package.json': {
                    name: 'parent-project',
                    dependencies: {
                        '@sap/cds': '5.0.0',
                    },
                },
            };
            setupMockPackageJson(packageJsonFiles);
            const filePaths = ['/source-root/subdir/file.cds'];
            const sourceRoot = '/source-root';
            const result = (0, packageManager_1.findPackageJsonDirs)(filePaths, '/mock/codeql', sourceRoot);
            // Should only find the package.json in source root, not the one above it
            expect(result.size).toBe(1);
            expect(Array.from(result)[0]).toBe('/source-root');
        });
        it('should find multiple sub-projects under a common source root', () => {
            // Setup complex directory structure with multiple projects
            const dirStructure = {
                '/source-root/project1/src/file1.cds': '/source-root/project1/src',
                '/source-root/project1/src': '/source-root/project1',
                '/source-root/project1': '/source-root',
                '/source-root/project2/src/file2.cds': '/source-root/project2/src',
                '/source-root/project2/src': '/source-root/project2',
                '/source-root/project2': '/source-root',
                '/source-root/non-cds-project/file3.cds': '/source-root/non-cds-project',
                '/source-root/non-cds-project': '/source-root',
                '/source-root': '/',
            };
            setupMockDirectoryStructure(dirStructure);
            // Multiple package.json files with different contents
            const packageJsonFiles = {
                // Root project with @sap/cds
                '/source-root/package.json': {
                    name: 'root-project',
                    dependencies: {
                        '@sap/cds': '5.0.0',
                    },
                },
                // Subproject 1 with @sap/cds
                '/source-root/project1/package.json': {
                    name: 'project1',
                    dependencies: {
                        '@sap/cds': '4.5.0',
                    },
                },
                // Subproject 2 with @sap/cds
                '/source-root/project2/package.json': {
                    name: 'project2',
                    dependencies: {
                        '@sap/cds': '4.7.0',
                    },
                },
                // Non-CDS project
                '/source-root/non-cds-project/package.json': {
                    name: 'non-cds-project',
                    dependencies: {
                        'other-dep': '1.0.0',
                    },
                },
            };
            setupMockPackageJson(packageJsonFiles);
            // Test with files from all projects
            const filePaths = [
                '/source-root/project1/src/file1.cds',
                '/source-root/project2/src/file2.cds',
                '/source-root/non-cds-project/file3.cds',
            ];
            const sourceRoot = '/source-root';
            const result = (0, packageManager_1.findPackageJsonDirs)(filePaths, '/mock/codeql', sourceRoot);
            // Should find three CDS projects (root + two subprojects)
            expect(result.size).toBe(3);
            expect(Array.from(result).sort()).toEqual(['/source-root', '/source-root/project1', '/source-root/project2'].sort());
        });
        it('should detect a source root that is not a CDS project itself', () => {
            // Setup directory structure where source root doesn't have @sap/cds
            const dirStructure = {
                '/source-root/project1/src/file1.cds': '/source-root/project1/src',
                '/source-root/project1/src': '/source-root/project1',
                '/source-root/project1': '/source-root',
                '/source-root': '/',
            };
            setupMockDirectoryStructure(dirStructure);
            const packageJsonFiles = {
                // Root project WITHOUT @sap/cds
                '/source-root/package.json': {
                    name: 'root-project',
                    dependencies: {
                        'other-dep': '1.0.0',
                    },
                },
                // Subproject with @sap/cds
                '/source-root/project1/package.json': {
                    name: 'project1',
                    dependencies: {
                        '@sap/cds': '4.5.0',
                    },
                },
            };
            setupMockPackageJson(packageJsonFiles);
            const filePaths = ['/source-root/project1/src/file1.cds'];
            const sourceRoot = '/source-root';
            const result = (0, packageManager_1.findPackageJsonDirs)(filePaths, '/mock/codeql', sourceRoot);
            // Should only find the subproject, not the root
            expect(result.size).toBe(1);
            expect(Array.from(result)[0]).toBe('/source-root/project1');
        });
        it('should handle edge case with no existing package.json files', () => {
            // Setup directory structure with no package.json
            const dirStructure = {
                '/source-root/file.cds': '/source-root',
                '/source-root': '/',
            };
            setupMockDirectoryStructure(dirStructure);
            // No package.json files exist
            setupMockPackageJson({});
            const filePaths = ['/source-root/file.cds'];
            const sourceRoot = '/source-root';
            const result = (0, packageManager_1.findPackageJsonDirs)(filePaths, '/mock/codeql', sourceRoot);
            // Should find no projects
            expect(result.size).toBe(0);
        });
    });
    describe('installDependencies', () => {
        it('should install dependencies for each directory', () => {
            const packageJsonDirs = new Set(['/project1', '/project2']);
            const mockCodeqlPath = '/mock/codeql';
            (0, packageManager_1.installDependencies)(packageJsonDirs, mockCodeqlPath);
            // Check npm install was called for each directory
            expect(childProcess.execFileSync).toHaveBeenCalledTimes(4); // 2 directories x 2 calls per directory
            // Check first npm install call for project1
            expect(childProcess.execFileSync).toHaveBeenNthCalledWith(1, 'npm', ['install', '--quiet', '--no-audit', '--no-fund'], expect.objectContaining({ cwd: '/project1' }));
            // Check @sap/cds-dk install call for project1
            expect(childProcess.execFileSync).toHaveBeenNthCalledWith(2, 'npm', ['install', '--quiet', '--no-audit', '--no-fund', '--no-save', '@sap/cds-dk'], expect.objectContaining({ cwd: '/project1' }));
        });
        it('should log warning when no directories are found', () => {
            const packageJsonDirs = new Set();
            // Mock console.warn
            const originalConsoleWarn = console.warn;
            console.warn = jest.fn();
            (0, packageManager_1.installDependencies)(packageJsonDirs, '/mock/codeql');
            expect(childProcess.execFileSync).not.toHaveBeenCalled();
            expect(console.warn).toHaveBeenCalledWith('WARN: failed to detect any package.json directories for cds compiler installation.');
            // Restore console.warn
            console.warn = originalConsoleWarn;
        });
        it('should add diagnostic when npm install fails', () => {
            const packageJsonDirs = new Set(['/project-error']);
            const mockCodeqlPath = '/mock/codeql';
            // Mock error for execFileSync
            childProcess.execFileSync.mockImplementation(() => {
                throw new Error('npm install failed');
            });
            // Mock console.error
            const originalConsoleError = console.error;
            console.error = jest.fn();
            // Mock path.join
            path.join.mockImplementation((dir, file) => `${dir}/${file}`);
            (0, packageManager_1.installDependencies)(packageJsonDirs, mockCodeqlPath);
            expect(diagnostics_1.addDependencyDiagnostic).toHaveBeenCalledWith('/project-error/package.json', expect.stringContaining('npm install failed'), mockCodeqlPath);
            // Restore console.error
            console.error = originalConsoleError;
        });
    });
});
//# sourceMappingURL=packageManager.test.js.map