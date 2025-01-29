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
_script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

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

# Change to the directory of this script to ensure that npm looks up
# the package.json file in the correct directory and installs the
# dependencies (i.e. node_modules) relative to this directory.
cd "$_script_dir" && \
echo "Installing node package dependencies" && \
npm install --quiet --no-audit --no-fund && \
echo "Running the 'index-files.js' script" && \
node "$(dirname "$0")/index-files.js" "$_response_file_path"
