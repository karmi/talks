#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "\e[1mDeploying to Github Pages\e[0m\n"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ! git diff-files --quiet; then
  echo "Uncommited changes present, exiting..."
  exit 1
fi

git checkout gh-pages

rm -rf docs
mv _site docs

echo "talks.karmi.cz" > docs/CNAME

git add docs/

git commit -m "Update the website"
git push -f origin gh-pages

git checkout -
