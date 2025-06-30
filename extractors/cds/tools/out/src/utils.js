"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getArg = getArg;
exports.validateArguments = validateArguments;
const path_1 = require("path");
/**
 * Safely get a command-line parameter and properly resolve the path.
 * @param `args` - Command line arguments array.
 * @param `index` - Index of the argument to get.
 * @param `defaultValue` - Default value to return if argument is not present.
 * @returns The resolved argument value or the default value
 */
function getArg(args, index, defaultValue = '') {
    if (index < args.length) {
        // Handle the path resolution properly without unnecessary quoting
        return (0, path_1.resolve)(args[index]);
    }
    return defaultValue;
}
/**
 * Check if the script was invoked with the required arguments.
 * @param `args` Command line arguments to check.
 * @param `requiredCount` Number of required arguments.
 * @returns Boolean `true` if the script was invoked correctly, `false` otherwise.
 */
function validateArguments(args, requiredCount) {
    var _a, _b;
    if (args.length !== requiredCount) {
        // Extract the script name from the path properly
        const scriptPath = (_a = args[1]) !== null && _a !== void 0 ? _a : '';
        const scriptName = (_b = scriptPath.split(/[/\\]/).pop()) !== null && _b !== void 0 ? _b : 'index-files.js';
        console.warn(`Usage: node ${scriptName} <response-file> <source-root>`);
        return false;
    }
    return true;
}
//# sourceMappingURL=utils.js.map