#!/usr/bin/env bash

set -euxo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
OSMOSIS_REV=${1:-main}

# update revision in proto-build main.rs
PROTO_BUILD_MAIN_RS="$SCRIPT_DIR/../packages/proto-build/src/main.rs"

# use @ as a separator to avoid confusion on input like "origin/main"
sed -i "s@const OSMOSIS_REV: \&str = \".*\";@const OSMOSIS_REV: \&str = \"$OSMOSIS_REV\";@g" "$PROTO_BUILD_MAIN_RS"

git diff

# rebuild osmosis-std
cd "$SCRIPT_DIR/../packages/proto-build/" && cargo run -- --update-deps

# if dirty or untracked file exists
if [[ $(git diff --stat) != '' ||  $(git ls-files  --exclude-standard  --others) ]]; then
  # add, commit and push
  git add "$SCRIPT_DIR/.."
  git commit -m "rebuild with $(git rev-parse --short HEAD:dependencies/osmosis)"

  # remove "origin/"
  OSMOSIS_REV=$(echo "$OSMOSIS_REV" | sed "s/^origin\///")
  BRANCH="autobuild-$OSMOSIS_REV"
  git checkout -b "$BRANCH"
  git push -uf origin "$BRANCH"
else
  echo '[CLEAN] No update needed for this build'
fi
