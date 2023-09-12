#!/bin/bash

# https://gitlab.com/quarto-forge/docker

docker run --rm -it -v $PWD:/tmp \
  registry.gitlab.com/quarto-forge/docker/quarto \
  quarto render library-and-maze-czpycon2023.ipynb --output index.html
