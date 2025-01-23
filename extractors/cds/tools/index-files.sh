#!/usr/bin/env bash

set -eu

if [ $# -ne 1 ]
then
    echo "Usage:  $0 <response_file_path>"
    exit 1
fi

if ! command -v node > /dev/null
then
    echo "node executable is required (in PATH) to run the 'index-files.js' script. Please install Node.js and try again."
    exit 2
fi

if ! command -v npm > /dev/null
then
    echo "npm executable is required (in PATH) to install the dependencies for the 'index-files.js' script."
    exit 3
fi

_response_file_path="$1"

echo "Checking response file for CDS files to index"

# Terminate early if the _response_file_path doesn't exist or is empty,
# which indicates that no CDS files were selected or found.
if [ ! -f "$_response_file_path" ] || [ ! -s "$_response_file_path" ]
then
    echo "'codeql database index-files --language cds' command terminated early as response file '$_response_file_path' does not exist or is empty. This is because no CDS files were selected or found."
    # Exit without error to avoid failing any calling (javascript)
    # extractor, and llow the tool the report the lack of coverage
    # for CDS files.
    exit 0
fi

echo "Installing node package dependencies and running the 'index-files.js' script"
npm install --quiet --no-audit --no-fund --no-package-json && \
node "$(dirname "$0")/index-files.js" "$_response_file_path"