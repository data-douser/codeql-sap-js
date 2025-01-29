#!/usr/bin/env bash

set -eu

# NOTE: the code below is copied in three places:
#  - scripts/compile-cds.sh
#  - extractors/cds/tools/autobuild.sh (here)
#  - extractors/javascript/tools/pre-finalize.sh
# Any changes should be synchronized between these three places.

exec "${CODEQL_DIST}/codeql" database index-files \
    --include-extension=.cds \
    --language cds \
    --prune **/node_modules/**/* \
    --prune **/.eslint/**/* \
    --total-size-limit=10m \
    -- \
    "$CODEQL_EXTRACTOR_CDS_WIP_DATABASE"
