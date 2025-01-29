const { execFileSync, execSync, spawnSync } = require('child_process');
const { existsSync, readFileSync, statSync } = require('fs');
const { arch, platform } = require('os');
const { dirname, join, resolve } = require('path');
const { quote } = require('shell-quote');

console.log('Indexing CDS files');

const responseFile = process.argv[2];

const osPlatform = platform();
const osPlatformArch = arch();
console.log(`Detected OS platform=${osPlatform} : arch=${osPlatformArch}`);
const autobuildScriptName = osPlatform === 'win32' ? 'autobuild.cmd' : 'autobuild.sh';
const autobuildScriptPath = join(
    process.env.CODEQL_EXTRACTOR_JAVASCRIPT_ROOT, 'tools', autobuildScriptName
);
const codeqlExe = osPlatform === 'win32' ? 'codeql.exe' : 'codeql';
const codeqlExePath = join(quote([process.env.CODEQL_DIST]), codeqlExe);

/**
 * Terminate early if:
 *   - the javascript extractor autobuild script does not exist; or
 *   - the codeql executable does not exist; or
 *   - the input responseFile does not exist; or
 *   - the input responseFile is empty or could not be parsed as a list of file paths.
 */
if (!existsSync(autobuildScriptPath)) {
    console.warn(`'${codeqlExe} database index-files --language cds' terminated early as autobuild script '${autobuildScriptPath}' does not exist.`);
    process.exit(0);
}
if (!existsSync(codeqlExePath)) {
    console.warn(`'${codeqlExe} database index-files --language cds' terminated early as codeql executable '${codeqlExePath}' does not exist.`);
    process.exit(0);
}
if (!existsSync(responseFile)) {
    console.warn(`'${codeqlExe} database index-files --language cds' terminated early as response file '${responseFile}' does not exist. This is because no CDS files were selected or found.`);
    process.exit(0);
}

let responseFiles = [];
try {
    // Read the response file and split it into lines, removing (filter(Boolean)) empty lines.
    responseFiles = readFileSync(responseFile, 'utf-8').split('\n').filter(Boolean);
    if (statSync(responseFile).size === 0 || responseFiles.length === 0) {
        console.warn(`'${codeqlExe} database index-files --language cds' terminated early as response file '${responseFile}' is empty. This is because no CDS files were selected or found.`);
        process.exit(0);
    }
} catch (err) {
    console.warn(`'${codeqlExe} database index-files --language cds' terminated early as response file '${responseFile}' could not be read due to an error: ${err}`);
    process.exit(0);
}

// Determine if we have the cds commands available. If not, install the cds develpment kit
// (cds-dk) in the appropriate directories and use npx to run the cds command from there.
let cdsCommand = 'cds';
try {
    execFileSync('cds', ['--version'], { stdio: 'ignore' });
} catch {
    console.log('Pre-installing cds compiler');

    // Use a JS `Set` to avoid duplicate processing of the same directory.
    const packageJsonDirs = new Set();
    /**
     * Find all the directories containing a package.json with a dependency on `@sap/cds`,
     * where the directory contains at least one of the files listed in the response file
     * (e.g. the cds files we want to extract).
     *
     * We then install the CDS development kit (`@sap/cds-dk`) in each directory, which
     * makes the `cds` command usable from the npx command within that directory.
     *
     * Nested package.json files simply cause the package to be installed in the parent
     * node_modules directory.
     *
     * TODO : fix implementation or change ^comment^ to reflect the actual implementation.
     *
     * We also ensure we skip node_modules, as we can end up in a recursive loop.
     */
    responseFiles.forEach(file => {
        let dir = dirname(quote([file]));
        while (dir !== resolve(dir, '..')) {
            const packageJsonPath = join(dir, 'package.json');
            if (existsSync(packageJsonPath)) {
                const rawData = readFileSync(packageJsonPath, 'utf-8');
                const packageJsonData = JSON.parse(rawData);
                // Check if the 'name' and 'dependencies' properties are present in the
                // package.json file at packageJsonPath.
                if (
                    packageJsonData.name &&
                    packageJsonData.dependencies &&
                    typeof packageJsonData.dependencies === 'object'
                ) {
                    const dependencyNames = Object.keys(packageJsonData.dependencies);
                    if (
                        dependencyNames.includes('@sap/cds')
                        &&
                        dependencyNames.includes('@sap/cds-dk')
                    ) {
                        packageJsonDirs.add(dir);
                        break;
                    }
                }
            }
            // Move up one directory level and try again to find a package.json file
            // for the response file.
            dir = resolve(dir, '..');
        }
    });

    // TODO : revise this check as the equality is probably not guaranteed.
    if (responseFiles.length !== packageJsonDirs.length) {
        console.warn(
            `WARN: mismatch between number of response files (${responseFiles.length}) and package.json directories (${packageJsonDirs.length})`
        );
    }

    packageJsonDirs.forEach((dir) => {
        console.log(`Installing node packages into ${dir} to enable CDS compilation.`);
        execFileSync(
            'npm',
            ['install', '--quiet', '--no-audit', '--no-fund'],
            { cwd: dir, stdio: 'inherit' }
        );
    });

    /**
     * Use the `npx` command to dynamically install the CDS development kit (`@sap/cds-dk`)
     * package if necessary, which then provides the `cds` command line tool in directories
     * which are not covered by the package.json install command approach above.
     */
    cdsCommand = 'npx -y --package @sap/cds-dk cds';
}

console.log('Processing CDS files to JSON');

/**
 * Run the cds compile command on each file in the response files list, outputting the
 * compiled JSON to a file with the same name but with a .json extension appended.
 */
responseFiles.forEach(rawCdsFilePath => {
    const cdsFilePath = quote([rawCdsFilePath]);
    const cdsJsonFilePath = `${cdsFilePath}.json`;
    console.log(`Processing CDS file ${cdsFilePath} to: ${cdsJsonFilePath}`);
    const result = spawnSync(
        cdsCommand,
        ['compile', cdsFilePath, '-2', 'json', '-o', cdsJsonFilePath, '--locations'],
        { shell: true }
    );
    if (result.error || result.status !== 0) {
        const stderrTruncated = quote(
            result.stderr.toString().split('\n').filter(line => line.startsWith('[ERROR]')).slice(-4).join('\n'));
        const errorMessage = `Could not compile the file ${cdsFilePath}.\nReported error(s):\n\`\`\`\n${stderrTruncated}\n\`\`\``;
        console.log(errorMessage);
        execFileSync(
            codeqlExePath,
            [
                'database',
                'add-diagnostic',
                '--extractor-name=cds',
                '--ready-for-status-page',
                '--source-id=cds/compilation-failure',
                '--source-name="Failure to compile one or more SAP CAP CDS files"',
                '--severity=error',
                `--markdown-message="${errorMessage}"`,
                `--file-path="${cdsFilePath}"`,
                '--',
                `${process.env.CODEQL_EXTRACTOR_CDS_WIP_DATABASE}`
            ],
        );
    }
});

// Check if the (JavaScript) JS extractor variables are set, and set them if not.
if (!process.env.CODEQL_EXTRACTOR_JAVASCRIPT_ROOT) {
    // Find the JS extractor location.
    process.env.CODEQL_EXTRACTOR_JAVASCRIPT_ROOT = execFileSync(
        codeqlExePath,
        ['resolve', 'extractor', '--language=javascript']
    ).toString().trim();
    // Set the JAVASCRIPT extractor environment variables to the same as the CDS
    // extractor environment variables so that the JS extractor will write to the
    // CDS database.
    process.env.CODEQL_EXTRACTOR_JAVASCRIPT_WIP_DATABASE = process.env.CODEQL_EXTRACTOR_CDS_WIP_DATABASE;
    process.env.CODEQL_EXTRACTOR_JAVASCRIPT_DIAGNOSTIC_DIR = process.env.CODEQL_EXTRACTOR_CDS_DIAGNOSTIC_DIR;
    process.env.CODEQL_EXTRACTOR_JAVASCRIPT_LOG_DIR = process.env.CODEQL_EXTRACTOR_CDS_LOG_DIR;
    process.env.CODEQL_EXTRACTOR_JAVASCRIPT_SCRATCH_DIR = process.env.CODEQL_EXTRACTOR_CDS_SCRATCH_DIR;
    process.env.CODEQL_EXTRACTOR_JAVASCRIPT_TRAP_DIR = process.env.CODEQL_EXTRACTOR_CDS_TRAP_DIR;
    process.env.CODEQL_EXTRACTOR_JAVASCRIPT_SOURCE_ARCHIVE_DIR = process.env.CODEQL_EXTRACTOR_CDS_SOURCE_ARCHIVE_DIR;
}

let excludeFilters = '';
/**
 * Check if LGTM_INDEX_FILTERS is already set. This tyically happens if either
 * "paths" and/or "paths-ignore" is set in the lgtm.yml file.
 */
if (process.env.LGTM_INDEX_FILTERS) {
    console.log(`Found $LGTM_INDEX_FILTERS already set to:\n${process.env.LGTM_INDEX_FILTERS}`);
    const allowedExcludePatterns = [
        join('exclude:**', '*'),
        join('exclude:**', '*.*'),
    ];
    /**
     * If it is set, we will try to honor the paths-ignore filter.
     *
     * Split by `\n` and find all the entries that start with exclude, with some
     * exclusions allowed for supported glob patterns, and then join them back
     * together with `\n`.
     */
    excludeFilters = '\n' + process.env.LGTM_INDEX_FILTERS
        .split('\n')
        .filter(line =>
            line.startsWith('exclude')
            &&
            !allowedExcludePatterns.some(pattern => line.includes(pattern))
        ).join('\n');
}

// Enable extraction of the .cds.json files only.
const lgtmIndexFiltersPatterns = [
    join('exclude:**', '*.*'),
    join('include:**', '*.cds.json'),
    join('include:**', '*.cds'),
    join('exclude:**', 'node_modules', '**', '*.*')
].join('\n');;
process.env.LGTM_INDEX_FILTERS = lgtmIndexFiltersPatterns + excludeFilters;
console.log(`Set $LGTM_INDEX_FILTERS to:\n${process.env.LGTM_INDEX_FILTERS}`);
process.env.LGTM_INDEX_TYPESCRIPT = 'NONE';
// Configure to copy over the .cds files as well, by pretending they are JSON.
process.env.LGTM_INDEX_FILETYPES = '.cds:JSON';
// Ignore the LGTM_INDEX_INCLUDE variable for this purpose as it may explicitly
// refer to .js or .ts files.
delete process.env.LGTM_INDEX_INCLUDE;

console.log('Extracting the .cds.json files');

console.log(`Running 'javascript' extractor autobuild script: ${autobuildScriptPath}`);
/**
 * Invoke the javascript autobuilder to index the .cds.json files only.
 *
 * Environment variables must be passed from this script's process to the
 * process that invokes the autobuild script, otherwise the CDS autobuild.sh
 * script will not be invoked by the autobuild script built into the
 * 'javascript' extractor.
 */
spawnSync(
    autobuildScriptPath,
    [],
    { env: process.env, shell: true, stdio: 'inherit' }
);
