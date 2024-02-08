#!/bin/bash

# https://gitlab.com/quarto-forge/docker

# docker run --rm -it -v $PWD:/tmp \
#   registry.gitlab.com/quarto-forge/docker/quarto \
#   quarto render wikipedia-semantic-search.ipynb --output index.html

# curl -L -O https://github.com/quarto-dev/quarto-cli/releases/download/v1.3.450/quarto-1.3.450-linux-amd64.deb
# dpkg -i quarto-1.3.450-linux-amd64.deb
# quarto render wikipedia-semantic-search.ipynb --output index.html

# Local

quarto render wikipedia-semantic-search.ipynb --output index.html --quiet

rm -rf _site
mkdir -p _site/wikipedia-semantic-search/assets/

mv -f index.html _site/wikipedia-semantic-search/
mv -f wikipedia-semantic-search_files/ _site/wikipedia-semantic-search/

cp -r assets/ _site/wikipedia-semantic-search/assets/

cp style.css _site/wikipedia-semantic-search/

mkdir -p ../_site/
mv _site/wikipedia-semantic-search/ ../_site/wikipedia/
rm -rf _site
