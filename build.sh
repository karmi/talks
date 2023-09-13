#!/bin/bash

rm -rf _site
mkdir -p _site

echo "Building projects..."

for dir in */ ; do
    if [ -f "${dir}/build.sh" ]; then
        echo "Building project in [$dir]"
        echo "------------------------------------------------------------"
        (cd "$dir" && /bin/bash build.sh)
    else
        echo "Skipping [$dir], no build file present."
    fi
done

echo "Deploying to Github Pages"

git checkout gh-pages

rm -rf docs
mv _site docs
git add docs/

git commit -m "Update the website"
git push -f origin gh-pages

git checkout main
