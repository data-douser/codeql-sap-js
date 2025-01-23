const { existsSync, readFileSync, statSync } = require('fs');
const { execSync, spawnSync } = require('child_process');
const { dirname, join, resolve } = require('path');

console.log('Indexing CDS files');

const responseFile = process.argv[2];

const npmInstallCmdWithArgs = 'npm install --quiet --no-audit --no-fund --no-package-lock';

if (!existsSync(responseFile)) {
    console.log(`'codeql database index-files --language cds' terminated early as response file '${responseFile}' does not exist. This is because no CDS files were selected or found.`);
    process.exit(0);
}

if (statSync(responseFile).size === 0) {
    console.log(`'codeql database index-files --language cds' terminated early as response file '${responseFile}' is empty. This is because no CDS files were selected or found.`);
    process.exit(0);
}

let cdsCommand = 'cds';
try {
    execSync('cds --version', { stdio: 'ignore' });
} catch {
    console.log('Pre-installing cds compiler');
    const responseFiles = readFileSync(responseFile, 'utf-8').split('\n').filter(Boolean);
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

    cdsCommand = 'npx -y --package @sap/cds-dk cds';
}

console.log('Processing CDS files to JSON');

const responseFiles = readFileSync(responseFile, 'utf-8').split('\n').filter(Boolean);
responseFiles.forEach(cdsFile => {
    const cdsJsonFile = `${cdsFile}.json`;
    console.log(`Processing CDS file ${cdsFile} to: ${cdsJsonFile}`);
    const result = spawnSync(cdsCommand, ['compile', cdsFile, '-2', 'json', '-o', cdsJsonFile, '--locations'], { shell: true });
    if (result.error || result.status !== 0) {
        const stderrTruncated = result.stderr.toString().split('\n').filter(line => line.startsWith('[ERROR]')).slice(-4).join('\n');
        const errorMessage = `Could not compile the file ${cdsFile}.\nReported error(s):\n\`\`\`\n${stderrTruncated}\n\`\`\``;
        console.log(errorMessage);
        execSync(`${process.env.CODEQL_DIST}/codeql database add-diagnostic --extractor-name cds --ready-for-status-page --source-id cds/compilation-failure --source-name "Failure to compile one or more SAP CAP CDS files" --severity error --markdown-message "${errorMessage}" --file-path "${cdsFile}" "${process.env.CODEQL_EXTRACTOR_CDS_WIP_DATABASE}"`);
    }
});

if (!process.env.CODEQL_EXTRACTOR_JAVASCRIPT_ROOT) {
    process.env.CODEQL_EXTRACTOR_JAVASCRIPT_ROOT = execSync(`${process.env.CODEQL_DIST}/codeql resolve extractor --language=javascript`).toString().trim();
    process.env.CODEQL_EXTRACTOR_JAVASCRIPT_WIP_DATABASE = process.env.CODEQL_EXTRACTOR_CDS_WIP_DATABASE;
    process.env.CODEQL_EXTRACTOR_JAVASCRIPT_DIAGNOSTIC_DIR = process.env.CODEQL_EXTRACTOR_CDS_DIAGNOSTIC_DIR;
    process.env.CODEQL_EXTRACTOR_JAVASCRIPT_LOG_DIR = process.env.CODEQL_EXTRACTOR_CDS_LOG_DIR;
    process.env.CODEQL_EXTRACTOR_JAVASCRIPT_SCRATCH_DIR = process.env.CODEQL_EXTRACTOR_CDS_SCRATCH_DIR;
    process.env.CODEQL_EXTRACTOR_JAVASCRIPT_TRAP_DIR = process.env.CODEQL_EXTRACTOR_CDS_TRAP_DIR;
    process.env.CODEQL_EXTRACTOR_JAVASCRIPT_SOURCE_ARCHIVE_DIR = process.env.CODEQL_EXTRACTOR_CDS_SOURCE_ARCHIVE_DIR;
}

let excludeFilters = '';
if (process.env.LGTM_INDEX_FILTERS) {
    console.log(`Found $LGTM_INDEX_FILTERS already set to:\n${process.env.LGTM_INDEX_FILTERS}`);
    excludeFilters = '\n' + process.env.LGTM_INDEX_FILTERS.split('\n').filter(line => line.startsWith('exclude') && !['exclude:**/*', 'exclude:**/*.*'].includes(line)).join('\n');
}

process.env.LGTM_INDEX_FILTERS = `exclude:**/*.*\ninclude:**/*.cds.json\ninclude:**/*.cds\nexclude:**/node_modules/**/*.*${excludeFilters}`;
console.log(`Setting $LGTM_INDEX_FILTERS to:\n${process.env.LGTM_INDEX_FILTERS}`);
process.env.LGTM_INDEX_TYPESCRIPT = 'NONE';
process.env.LGTM_INDEX_FILETYPES = '.cds:JSON';
delete process.env.LGTM_INDEX_INCLUDE;

console.log('Extracting the cds.json files');

execSync(`${process.env.CODEQL_EXTRACTOR_JAVASCRIPT_ROOT}/tools/autobuild.sh`, { stdio: 'inherit' });
