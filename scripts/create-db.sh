#!/bin/bash
# !!!!!!! Run it at test/queries/ !!!!!!!

# Remember current directory
TEST_DIR=$(pwd)

# Loop over all the directories in the test directory
for dir in *; do
    # Change to the directory
    cd $dir

    # Remember this folder's name
    FOLDER_NAME=$(basename $(pwd))

    # Enable XML extraction
    export LGTM_INDEX_XML_MODE='ALL'

    # Enable JSON extraction
    export LGTM_INDEX_FILTERS=include:**/*.json

    # Create CodeQL database
    codeql database create $FOLDER_NAME --language=javascript --overwrite

    # Change back to the test directory
    cd $TEST_DIR
done

echo "Done!"
