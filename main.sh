#!/usr/bin/env bash

set -eu

repo_uri="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
remote_name="origin"
main_branch="master"
gh_pages_branch="gh-pages"


git config user.name "$GITHUB_ACTOR"
git config user.email "${GITHUB_ACTOR}@bots.github.com"


git checkout "$gh_pages_branch"

mkdir tmp
mkdir tmp/resources
mkdir tmp/v2
mkdir tmp/updatelog

cp ./data.json ./tmp/data_prev.json
cp ./raw_data1.json ./tmp
cp ./deaths_recoveries1.json ./tmp
cp -r ./updatelog ./tmp
cp -r ./csv ./tmp
cp -r ./districts_daily ./tmp
cp -r ./resources ./tmp

git checkout "$main_branch"


node src/sheet-to-json_generic.js

# pip3 install --quiet -r requirements.txt
# python3 src/geocoder.py

cp README.md tmp/
cp -r projects/ tmp/

node src/sheets-to-csv.js

node src/states_daily_to_csv.js
node src/district_data_generator.js
node src/concat_data.js
node src/split_raw_data.js
node src/snapshot_zones.js 
node src/generate_districts_daily.js
node src/generate_locale.js
# node src/ultimate_parser.js

node src/sanity_check.js
node src/generate_activity_log.js

git checkout "$gh_pages_branch"

rm tmp/data_prev.json
cp -r tmp/* .
rm -r tmp/



git add .
set +e  # Grep succeeds with nonzero exit codes to show results.
git status | grep 'new file\|modified'
if [ $? -eq 0 ]
then
    set -e
    git commit -am "data updated on - $(date)"
    git remote set-url "$remote_name" "$repo_uri" # includes access token
    git push --force-with-lease "$remote_name" "$gh_pages_branch"
else
    set -e
    echo "No changes since last run"
fi

echo "finish"