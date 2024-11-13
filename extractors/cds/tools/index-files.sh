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
    # Use the npx command to dynamically install the cds development kit (@sap/cds-dk) package if necessary,
    # which then provides the cds command line tool.
    cds_command="npx -y --package @sap/cds-dk cds"
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
# Configure to copy over the CDS files as well, by pretending they are JSON
export LGTM_INDEX_FILETYPES=".cds:JSON"

echo "Extracting the cds.json files"

# Invoke the JavaScript autobuilder to index the .cds.json files only
"$CODEQL_EXTRACTOR_JAVASCRIPT_ROOT"/tools/autobuild.sh