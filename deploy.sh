#!/bin/bash

echo "Deploying to Github Pages"

git checkout gh-pages

rm -rf docs
mv _site docs

echo "talks.karmi.cz" > docs/CNAME

git add docs/

git commit -m "Update the website"
git push -f origin gh-pages

git checkout -
