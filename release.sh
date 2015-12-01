#!/bin/bash

readonly projectName="GasJot-ios"
readonly version="$1"
readonly tagLabel="${version}"

agvtool new-version -all ${version}
git add .
git commit -m 'prep for release: ${version}'

git tag -f -a $tagLabel -m 'version $version'
git push -f --tags
