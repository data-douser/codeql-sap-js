"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getPlatformInfo = getPlatformInfo;
exports.getCodeQLExePath = getCodeQLExePath;
exports.getJavaScriptExtractorRoot = getJavaScriptExtractorRoot;
exports.setupJavaScriptExtractorEnv = setupJavaScriptExtractorEnv;
exports.getAutobuildScriptPath = getAutobuildScriptPath;
exports.configureLgtmIndexFilters = configureLgtmIndexFilters;
exports.setupAndValidateEnvironment = setupAndValidateEnvironment;
const child_process_1 = require("child_process");
const os_1 = require("os");
const path_1 = require("path");
const filesystem_1 = require("./filesystem");
/**
 * Get platform information
 * @returns Platform information including OS platform, architecture, and whether it's Windows
 */
function getPlatformInfo() {
    const osPlatform = (0, os_1.platform)();
    const osPlatformArch = (0, os_1.arch)();
    const isWindows = osPlatform === 'win32';
    const exeExtension = isWindows ? '.exe' : '';
    return {
        platform: osPlatform,
        arch: osPlatformArch,
        isWindows,
        exeExtension,
    };
}
/**
 * Get the path to the CodeQL executable
 * @returns The resolved path to the CodeQL executable
 */
function getCodeQLExePath() {
    var _a;
    const platformInfo = getPlatformInfo();
    const codeqlExe = platformInfo.isWindows ? 'codeql.exe' : 'codeql';
    // Safely get CODEQL_DIST environment variable
    const codeqlDist = (_a = process.env.CODEQL_DIST) !== null && _a !== void 0 ? _a : '';
    return (0, path_1.resolve)((0, path_1.join)(codeqlDist, codeqlExe));
}
/**
 * Get the JavaScript extractor root path
 * @param codeqlExePath The path to the CodeQL executable
 * @returns The JavaScript extractor root path
 */
function getJavaScriptExtractorRoot(codeqlExePath) {
    var _a;
    let jsExtractorRoot = (_a = process.env.CODEQL_EXTRACTOR_JAVASCRIPT_ROOT) !== null && _a !== void 0 ? _a : '';
    if (!jsExtractorRoot) {
        try {
            jsExtractorRoot = (0, child_process_1.execFileSync)(codeqlExePath, [
                'resolve',
                'extractor',
                '--language=javascript',
            ])
                .toString()
                .trim();
        }
        catch (error) {
            console.error(`Error resolving JavaScript extractor root: ${String(error)}`);
            return '';
        }
    }
    return jsExtractorRoot;
}
/**
 * Set JavaScript extractor environment variables using CDS extractor variables
 */
function setupJavaScriptExtractorEnv() {
    process.env.CODEQL_EXTRACTOR_JAVASCRIPT_WIP_DATABASE =
        process.env.CODEQL_EXTRACTOR_CDS_WIP_DATABASE;
    process.env.CODEQL_EXTRACTOR_JAVASCRIPT_DIAGNOSTIC_DIR =
        process.env.CODEQL_EXTRACTOR_CDS_DIAGNOSTIC_DIR;
    process.env.CODEQL_EXTRACTOR_JAVASCRIPT_LOG_DIR = process.env.CODEQL_EXTRACTOR_CDS_LOG_DIR;
    process.env.CODEQL_EXTRACTOR_JAVASCRIPT_SCRATCH_DIR =
        process.env.CODEQL_EXTRACTOR_CDS_SCRATCH_DIR;
    process.env.CODEQL_EXTRACTOR_JAVASCRIPT_TRAP_DIR = process.env.CODEQL_EXTRACTOR_CDS_TRAP_DIR;
    process.env.CODEQL_EXTRACTOR_JAVASCRIPT_SOURCE_ARCHIVE_DIR =
        process.env.CODEQL_EXTRACTOR_CDS_SOURCE_ARCHIVE_DIR;
}
/**
 * Get the path to the autobuild script
 * @param jsExtractorRoot The JavaScript extractor root path
 * @returns The path to the autobuild script
 */
function getAutobuildScriptPath(jsExtractorRoot) {
    const platformInfo = getPlatformInfo();
    const autobuildScriptName = platformInfo.isWindows ? 'autobuild.cmd' : 'autobuild.sh';
    return (0, path_1.resolve)((0, path_1.join)(jsExtractorRoot, 'tools', autobuildScriptName));
}
/**
 * Configure LGTM index filters for CDS files
 */
function configureLgtmIndexFilters() {
    let excludeFilters = '';
    if (process.env.LGTM_INDEX_FILTERS) {
        console.log(`Found $LGTM_INDEX_FILTERS already set to:\n${process.env.LGTM_INDEX_FILTERS}`);
        const allowedExcludePatterns = [(0, path_1.join)('exclude:**', '*'), (0, path_1.join)('exclude:**', '*.*')];
        excludeFilters =
            '\n' +
                process.env.LGTM_INDEX_FILTERS.split('\n')
                    .filter(line => line.startsWith('exclude') &&
                    !allowedExcludePatterns.some(pattern => line.includes(pattern)))
                    .join('\n');
    }
    // Enable extraction of the .cds.json files only.
    const lgtmIndexFiltersPatterns = [
        (0, path_1.join)('exclude:**', '*.*'),
        (0, path_1.join)('include:**', '*.cds.json'),
        (0, path_1.join)('include:**', '*.cds'),
        (0, path_1.join)('exclude:**', 'node_modules', '**', '*.*'),
    ].join('\n');
    process.env.LGTM_INDEX_FILTERS = lgtmIndexFiltersPatterns + excludeFilters;
    process.env.LGTM_INDEX_TYPESCRIPT = 'NONE';
    // Configure to copy over the .cds files as well, by pretending they are JSON.
    process.env.LGTM_INDEX_FILETYPES = '.cds:JSON';
}
/**
 * Sets up the environment and validates key components for CDS extractor
 * @param sourceRoot The source root directory
 * @returns The environment setup result
 */
function setupAndValidateEnvironment(sourceRoot) {
    const errorMessages = [];
    const platformInfo = getPlatformInfo();
    // Get the CodeQL executable path
    const codeqlExePath = getCodeQLExePath();
    // Validate that the required source root directory exists
    if (!(0, filesystem_1.dirExists)(sourceRoot)) {
        errorMessages.push(`project root directory '${sourceRoot}' does not exist`);
    }
    // Setup JavaScript extractor environment
    const jsExtractorRoot = getJavaScriptExtractorRoot(codeqlExePath);
    if (!jsExtractorRoot) {
        errorMessages.push(`CODEQL_EXTRACTOR_JAVASCRIPT_ROOT environment variable is not set`);
    }
    // Set environment variables for JavaScript extractor
    if (jsExtractorRoot) {
        process.env.CODEQL_EXTRACTOR_JAVASCRIPT_ROOT = jsExtractorRoot;
        setupJavaScriptExtractorEnv();
    }
    // Get autobuild script path
    const autobuildScriptPath = jsExtractorRoot ? getAutobuildScriptPath(jsExtractorRoot) : '';
    return {
        success: errorMessages.length === 0,
        errorMessages,
        codeqlExePath,
        jsExtractorRoot,
        autobuildScriptPath,
        platformInfo,
    };
}
//# sourceMappingURL=environment.js.map