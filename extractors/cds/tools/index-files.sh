#!/bin/bash

set -eu

# Check if the list of files is empty
response_file="$1"

# If the response_file doesn't exist, terminate:
if [ ! -f "$response_file" ]; then
    echo "codeql database index-files --language cds terminated early as response file '$response_file' does not exist. This is because no CDS files were selected or found."
    exit 0
fi

# If the response_file is empty, terminate
if [ ! -s "$response_file" ]; then
    echo "codeql database index-files --language cds terminated early as response file '$response_file' is empty. This is because no CDS files were selected or found."
    exit 0
fi

# Ensure that we have the `cds` command
if ! command -v cds &> /dev/null
then
    # Find all the directories containing a package.json with a dependency on @sap/cds, then install
    # the cds development kit (@sap/cds-dk) in each directory, which makes the `cds` command usable
    # from the npx command within that directory.
    #
    # Nested package.json files simply cause the package to be installed in the parent node_modules
    # directory.
    #
    # We also ensure we skip node_modules, as we can end up in a recursive loop
    find . -type d -name node_modules -prune -false -o -type f \( -iname 'package.json' \) -exec grep -l '@sap/cds' {} + -execdir bash -c "echo \"Installing @sap/cds-dk into \$(pwd) to enable CDS compilation.\"" \; -execdir npm install @sap/cds-dk \;
    cds_command="npx cds"
else
    cds_command="cds"
fi

echo "Processing CDS files to JSON"

while IFS= read -r cds_file; do
    $cds_command compile "$cds_file" \
        -2 json \
        -o "$cds_file.json" \
        --locations
done < "$response_file"

# Check if the JS extractor variables are set, and set them if not
if [ -z "${CODEQL_EXTRACTOR_JAVASCRIPT_ROOT:-}" ]; then
    # Find the JavaScript extractor location
    export CODEQL_EXTRACTOR_JAVASCRIPT_ROOT="$("$CODEQL_DIST/codeql" resolve extractor --language=javascript)"    

    # Set the JAVASCRIPT extractor environment variables to the same as the CDS extractor environment variables
    # so that the JS extractor will write to the CDS database
    export CODEQL_EXTRACTOR_JAVASCRIPT_WIP_DATABASE="$CODEQL_EXTRACTOR_CDS_WIP_DATABASE"
    export CODEQL_EXTRACTOR_JAVASCRIPT_DIAGNOSTIC_DIR="$CODEQL_EXTRACTOR_CDS_DIAGNOSTIC_DIR"
    export CODEQL_EXTRACTOR_JAVASCRIPT_LOG_DIR="$CODEQL_EXTRACTOR_CDS_LOG_DIR"
    export CODEQL_EXTRACTOR_JAVASCRIPT_SCRATCH_DIR="$CODEQL_EXTRACTOR_CDS_SCRATCH_DIR"
    export CODEQL_EXTRACTOR_JAVASCRIPT_TRAP_DIR="$CODEQL_EXTRACTOR_CDS_TRAP_DIR"
    export CODEQL_EXTRACTOR_JAVASCRIPT_SOURCE_ARCHIVE_DIR="$CODEQL_EXTRACTOR_CDS_SOURCE_ARCHIVE_DIR"
fi

# Enable extraction of the cds.json files only
export LGTM_INDEX_FILTERS=$'exclude:**/*.*\ninclude:**/*cds.json'
export LGTM_INDEX_TYPESCRIPT="NONE"

echo "Extracting the cds.json files"

# Invoke the JavaScript autobuilder to index the .cds.json files only
"$CODEQL_EXTRACTOR_JAVASCRIPT_ROOT"/tools/autobuild.sh