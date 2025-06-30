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
const packageManager = __importStar(require("../../../src/packageManager"));
describe('packageManager index', () => {
    describe('exports', () => {
        it('should export installDependencies function', () => {
            expect(typeof packageManager.installDependencies).toBe('function');
        });
        it('should export version resolver functions', () => {
            expect(typeof packageManager.checkVersionCompatibility).toBe('function');
            expect(typeof packageManager.clearVersionCache).toBe('function');
            expect(typeof packageManager.compareVersions).toBe('function');
            expect(typeof packageManager.findBestAvailableVersion).toBe('function');
            expect(typeof packageManager.getAvailableVersions).toBe('function');
            expect(typeof packageManager.getCacheStatistics).toBe('function');
            expect(typeof packageManager.logCacheStatistics).toBe('function');
            expect(typeof packageManager.parseSemanticVersion).toBe('function');
            expect(typeof packageManager.resolveCdsVersions).toBe('function');
            expect(typeof packageManager.satisfiesRange).toBe('function');
        });
        it('should provide all expected exports', () => {
            const expectedExports = [
                'installDependencies',
                'checkVersionCompatibility',
                'clearVersionCache',
                'compareVersions',
                'findBestAvailableVersion',
                'getAvailableVersions',
                'getCacheStatistics',
                'logCacheStatistics',
                'parseSemanticVersion',
                'resolveCdsVersions',
                'satisfiesRange',
            ];
            for (const exportName of expectedExports) {
                expect(packageManager).toHaveProperty(exportName);
            }
            // Verify specific types directly
            expect(typeof packageManager.installDependencies).toBe('function');
            expect(typeof packageManager.checkVersionCompatibility).toBe('function');
            expect(typeof packageManager.parseSemanticVersion).toBe('function');
        });
        it('should export types correctly', () => {
            // Type exports are compile-time only, but we can verify the module structure
            expect(packageManager).toBeDefined();
        });
    });
    describe('integration', () => {
        it('should allow all functions to be called without errors', () => {
            // Test basic function calls don't throw (without mocking dependencies)
            expect(() => packageManager.clearVersionCache()).not.toThrow();
            expect(() => packageManager.getCacheStatistics()).not.toThrow();
            expect(() => packageManager.logCacheStatistics()).not.toThrow();
            // Test parsing functions with basic inputs
            const parsedVersion = packageManager.parseSemanticVersion('6.1.3');
            expect(parsedVersion).toBeDefined();
            expect(parsedVersion === null || parsedVersion === void 0 ? void 0 : parsedVersion.major).toBe(6);
            const parsedVersion2 = packageManager.parseSemanticVersion('6.2.0');
            expect(parsedVersion2).toBeDefined();
            expect(parsedVersion2 === null || parsedVersion2 === void 0 ? void 0 : parsedVersion2.major).toBe(6);
            // Test compatibility check
            const compatibility = packageManager.checkVersionCompatibility('6.1.3', '6.0.0');
            expect(compatibility).toBeDefined();
            expect(typeof compatibility.isCompatible).toBe('boolean');
        });
        it('should have working version comparison functions', () => {
            const version1 = packageManager.parseSemanticVersion('6.1.3');
            const version2 = packageManager.parseSemanticVersion('6.2.0');
            // These are guaranteed to be defined for valid versions
            expect(version1).not.toBeNull();
            expect(version2).not.toBeNull();
            // Use non-null assertion since we've verified they exist
            const comparison = packageManager.compareVersions(version1, version2);
            expect(typeof comparison).toBe('number');
            const satisfies = packageManager.satisfiesRange(version1, '6.1.3');
            expect(typeof satisfies).toBe('boolean');
            expect(satisfies).toBe(true);
        });
    });
});
//# sourceMappingURL=index.test.js.map