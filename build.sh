#!/bin/bash

for dir in */ ; do
    if [ -f "${dir}/build.sh" ]; then
        echo "Building project in [$dir]"
        echo "------------------------------------------------------------"
        (cd "$dir" && /bin/bash build.sh)
    else
        echo "Skipping [$dir], no build file present."
    fi
done
