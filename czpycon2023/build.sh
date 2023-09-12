#!/bin/bash

# https://gitlab.com/quarto-forge/docker

# docker run --rm -it -v $PWD:/tmp \
#   registry.gitlab.com/quarto-forge/docker/quarto \
#   quarto render library-and-maze-czpycon2023.ipynb --output index.html

# curl -L -O https://github.com/quarto-dev/quarto-cli/releases/download/v1.3.450/quarto-1.3.450-linux-amd64.deb
# dpkg -i quarto-1.3.450-linux-amd64.deb
# quarto render library-and-maze-czpycon2023.ipynb --output index.html

# Local

quarto render library-and-maze-czpycon2023.ipynb --output index.html --quiet

rm -rf _site
mkdir -p _site/czpycon2023/assets/

mv -f index.html _site/czpycon2023/
mv -f library-and-maze-czpycon2023_files/ _site/czpycon2023/

cp -r assets/ _site/czpycon2023/assets/

cp style.css _site/czpycon2023/

mkdir -p ../_site/
mv _site/czpycon2023/ ../_site/czpycon2023/
rm -rf _site
