const { execSync, spawnSync } = require('child_process');
const { existsSync, readFileSync, statSync } = require('fs');
const { arch, platform } = require('os');
const { dirname, join, resolve } = require('path');

console.log('Indexing CDS files');

const responseFile = process.argv[2];

const osPlatform = platform();
const osPlatformArch = arch();
console.log(`Detected OS platform=${osPlatform} : arch=${osPlatformArch}`);
const autobuildScriptName = osPlatform === 'win32' ? 'autobuild.cmd' : 'autobuild.sh';
const codeqlExe = osPlatform === 'win32' ? 'codeql.exe' : 'codeql';
const codeqlExePath = join(process.env.CODEQL_DIST, codeqlExe);
const npmInstallCmdWithArgs = 'npm install --quiet --no-audit --no-fund --no-package-lock';

// If the response file does not exist, terminate.
if (!existsSync(responseFile)) {
    console.log(`'codeql database index-files --language cds' terminated early as response file '${responseFile}' does not exist. This is because no CDS files were selected or found.`);
    process.exit(0);
}

const responseFiles = readFileSync(responseFile, 'utf-8').split('\n').filter(Boolean);
// If the response file is empty, terminate.
if (statSync(responseFile).size === 0 || !responseFiles) {
    console.log(`'codeql database index-files --language cds' terminated early as response file '${responseFile}' is empty. This is because no CDS files were selected or found.`);
    process.exit(0);
}

// Determine if we have the cds commands available. If not, install the cds develpment kit
// (cds-dk) in the appropriate directories and use npx to run the cds command from there.
let cdsCommand = 'cds';
try {
    execSync('cds --version', { stdio: 'ignore' });
} catch {
    console.log('Pre-installing cds compiler');

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
    const packageJsonDirs = new Set();
    responseFiles.forEach(file => {
        let dir = dirname(file);
        while (dir !== resolve(dir, '..')) {
            if (existsSync(join(dir, 'package.json')) && readFileSync(join(dir, 'package.json'), 'utf-8').includes('@sap/cds')) {
                packageJsonDirs.add(dir);
                break;
            }
            dir = resolve(dir, '..');
        }
    });

    packageJsonDirs.forEach(dir => {
        console.log(`Installing @sap/cds-dk into ${dir} to enable CDS compilation.`);
        execSync(`${npmInstallCmdWithArgs} @sap/cds-dk`, { cwd: dir });
        execSync(npmInstallCmdWithArgs, { cwd: dir });
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
responseFiles.forEach(cdsFile => {
    const cdsJsonFile = `${cdsFile}.json`;
    console.log(`Processing CDS file ${cdsFile} to: ${cdsJsonFile}`);
    const result = spawnSync(cdsCommand, ['compile', cdsFile, '-2', 'json', '-o', cdsJsonFile, '--locations'], { shell: true });
    if (result.error || result.status !== 0) {
        const stderrTruncated = result.stderr.toString().split('\n').filter(line => line.startsWith('[ERROR]')).slice(-4).join('\n');
        const errorMessage = `Could not compile the file ${cdsFile}.\nReported error(s):\n\`\`\`\n${stderrTruncated}\n\`\`\``;
        console.log(errorMessage);
        execSync(`${codeqlExePath} database add-diagnostic --extractor-name cds --ready-for-status-page --source-id=cds/compilation-failure --source-name="Failure to compile one or more SAP CAP CDS files" --severity=error --markdown-message="${errorMessage}" --file-path="${cdsFile}" -- "${process.env.CODEQL_EXTRACTOR_CDS_WIP_DATABASE}"`);
    }
});

// Check if the (JavaScript) JS extractor variables are set, and set them if not.
if (!process.env.CODEQL_EXTRACTOR_JAVASCRIPT_ROOT) {
    // Find the JS extractor location.
    process.env.CODEQL_EXTRACTOR_JAVASCRIPT_ROOT = execSync(`${codeqlExePath} resolve extractor --language=javascript`).toString().trim();
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
            !allowedExcludePatterns.includes(line)
        ).join('\n');
}

// Enable extraction of the .cds.json files only.
const lgtmIndexFiltersPatterns = join(
    'exclude:**', '*.*\ninclude:**', '*.cds.json\ninclude:**', '*.cds\nexclude:**', 'node_modules', '**', '*.*'
);
process.env.LGTM_INDEX_FILTERS = `${lgtmIndexFiltersPatterns}${excludeFilters}`;
console.log(`Setting $LGTM_INDEX_FILTERS to:\n${process.env.LGTM_INDEX_FILTERS}`);
process.env.LGTM_INDEX_TYPESCRIPT = 'NONE';
// Configure to copy over the .cds files as well, by pretending they are JSON.
process.env.LGTM_INDEX_FILETYPES = '.cds:JSON';
// Ignore the LGTM_INDEX_INCLUDE variable for this purpose as it may explicitly
// refer to .js or .ts files.
delete process.env.LGTM_INDEX_INCLUDE;

console.log('Extracting the cds.json files');

// Invoke the JS autobuilder to index the .cds.json files only.
const autobuildScriptPath = join(process.env.CODEQL_EXTRACTOR_JAVASCRIPT_ROOT, 'tools', autobuildScriptName);
execSync(autobuildScriptPath, { stdio: 'inherit' });
