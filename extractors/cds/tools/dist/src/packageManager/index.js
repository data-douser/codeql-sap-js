"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.satisfiesRange = exports.resolveCdsVersions = exports.parseSemanticVersion = exports.logCacheStatistics = exports.getCacheStatistics = exports.getAvailableVersions = exports.findBestAvailableVersion = exports.compareVersions = exports.clearVersionCache = exports.checkVersionCompatibility = exports.installDependencies = void 0;
// Export the new robust installer functionality (preferred)
var installer_1 = require("./installer");
Object.defineProperty(exports, "installDependencies", { enumerable: true, get: function () { return installer_1.installDependencies; } });
// Export version resolver functionality
var versionResolver_1 = require("./versionResolver");
Object.defineProperty(exports, "checkVersionCompatibility", { enumerable: true, get: function () { return versionResolver_1.checkVersionCompatibility; } });
Object.defineProperty(exports, "clearVersionCache", { enumerable: true, get: function () { return versionResolver_1.clearVersionCache; } });
Object.defineProperty(exports, "compareVersions", { enumerable: true, get: function () { return versionResolver_1.compareVersions; } });
Object.defineProperty(exports, "findBestAvailableVersion", { enumerable: true, get: function () { return versionResolver_1.findBestAvailableVersion; } });
Object.defineProperty(exports, "getAvailableVersions", { enumerable: true, get: function () { return versionResolver_1.getAvailableVersions; } });
Object.defineProperty(exports, "getCacheStatistics", { enumerable: true, get: function () { return versionResolver_1.getCacheStatistics; } });
Object.defineProperty(exports, "logCacheStatistics", { enumerable: true, get: function () { return versionResolver_1.logCacheStatistics; } });
Object.defineProperty(exports, "parseSemanticVersion", { enumerable: true, get: function () { return versionResolver_1.parseSemanticVersion; } });
Object.defineProperty(exports, "resolveCdsVersions", { enumerable: true, get: function () { return versionResolver_1.resolveCdsVersions; } });
Object.defineProperty(exports, "satisfiesRange", { enumerable: true, get: function () { return versionResolver_1.satisfiesRange; } });
//# sourceMappingURL=index.js.map