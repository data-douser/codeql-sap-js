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
const cdsCompiler_1 = require("../../src/cdsCompiler");
const filesystem = __importStar(require("../../src/filesystem"));
// Mock dependencies
jest.mock('child_process', () => ({
    execFileSync: jest.fn(),
    spawnSync: jest.fn(),
}));
jest.mock('fs', () => ({
    existsSync: jest.fn(),
}));
jest.mock('../../src/filesystem', () => ({
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
            childProcess.execFileSync.mockReturnValue(Buffer.from('4.6.0'));
            const result = (0, cdsCompiler_1.determineCdsCommand)();
            expect(result).toBe('cds');
            expect(childProcess.execFileSync).toHaveBeenCalledWith('cds', ['--version'], expect.objectContaining({ stdio: 'ignore' }));
        });
        it('should return "npx -y --package @sap/cds-dk cds" when cds command is not available', () => {
            // Mock error when executing "cds --version"
            childProcess.execFileSync.mockImplementation(() => {
                throw new Error('Command not found');
            });
            const result = (0, cdsCompiler_1.determineCdsCommand)();
            expect(result).toBe('npx -y --package @sap/cds-dk cds');
            expect(childProcess.execFileSync).toHaveBeenCalledWith('cds', ['--version'], expect.objectContaining({ stdio: 'ignore' }));
        });
    });
    describe('compileCdsToJson', () => {
        it('should successfully compile CDS file to JSON file', () => {
            const cdsFilePath = '/path/to/model.cds';
            const sourceRoot = '/path/to';
            const cdsCommand = 'cds';
            const expectedJsonPath = '/path/to/model.cds.json';
            // Mock filesystem.fileExists to return true for CDS file
            filesystem.fileExists.mockImplementation(path => path === cdsFilePath);
            // Mock successful compilation
            childProcess.spawnSync.mockReturnValue({
                status: 0,
                stderr: null,
                error: null,
            });
            // Mock that the output JSON file exists
            filesystem.fileExists.mockImplementation(path => path === cdsFilePath || path === expectedJsonPath);
            // Mock that the output is not a directory
            filesystem.dirExists.mockReturnValue(false);
            const result = (0, cdsCompiler_1.compileCdsToJson)(cdsFilePath, sourceRoot, cdsCommand);
            expect(result).toEqual({
                success: true,
                outputPath: expectedJsonPath,
            });
            expect(childProcess.spawnSync).toHaveBeenCalledWith(cdsCommand, [
                'compile',
                cdsFilePath,
                '--to',
                'json',
                '--dest',
                expectedJsonPath,
                '--locations',
                '--log-level',
                'warn',
            ], expect.objectContaining({
                cwd: sourceRoot,
                shell: true,
                stdio: 'pipe',
            }));
        });
        it('should handle CDS file that does not exist', () => {
            const cdsFilePath = '/path/to/nonexistent.cds';
            const sourceRoot = '/path/to';
            const cdsCommand = 'cds';
            // Mock filesystem.fileExists to return false for CDS file
            filesystem.fileExists.mockReturnValue(false);
            const result = (0, cdsCompiler_1.compileCdsToJson)(cdsFilePath, sourceRoot, cdsCommand);
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
            filesystem.fileExists.mockImplementation(path => path === cdsFilePath);
            // Mock compilation failure
            childProcess.spawnSync.mockReturnValue({
                status: 1,
                stderr: Buffer.from('Syntax error in CDS file'),
                error: null,
            });
            const result = (0, cdsCompiler_1.compileCdsToJson)(cdsFilePath, sourceRoot, cdsCommand);
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
            filesystem.fileExists.mockImplementation(path => path === cdsFilePath);
            // Mock successful compilation
            childProcess.spawnSync.mockReturnValue({
                status: 0,
                stderr: null,
                error: null,
            });
            // Mock that the output is a directory
            filesystem.fileExists.mockImplementation(path => path === cdsFilePath);
            filesystem.dirExists.mockImplementation(path => path === expectedJsonPath);
            const result = (0, cdsCompiler_1.compileCdsToJson)(cdsFilePath, sourceRoot, cdsCommand);
            expect(result).toEqual({
                success: true,
                outputPath: expectedJsonPath,
            });
            // Check if recursivelyRenameJsonFiles was called
            expect(filesystem.recursivelyRenameJsonFiles).toHaveBeenCalledWith(expectedJsonPath);
        });
    });
});
//# sourceMappingURL=cdsCompiler.test.js.map