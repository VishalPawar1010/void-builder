#!/usr/bin/env bash

if [[ -z "${BUILD_SOURCEVERSION}" ]]; then

    echo "running version.sh"
    # Check if vscode directory exists
    if [[ -d "./vscode" ]]; then
        echo "getting vscode source version..."
        # Get the current commit hash from the vscode repository
        CURRENT_DIR=$(pwd)
        cd ./vscode
        BUILD_SOURCEVERSION=$(git rev-parse HEAD)
        cd ..
    else
        # Fallback to previous method if vscode directory doesn't exist
        if type -t "sha1sum" &> /dev/null; then
          BUILD_SOURCEVERSION=$( echo "${RELEASE_VERSION/-*/}" | sha1sum | cut -d' ' -f1 )
        else
          npm install -g checksum

          BUILD_SOURCEVERSION=$( echo "${RELEASE_VERSION/-*/}" | checksum )
        fi
    fi

    echo "BUILD_SOURCEVERSION=\"${BUILD_SOURCEVERSION}\""

    # for GH actions
    if [[ "${GITHUB_ENV}" ]]; then
        echo "BUILD_SOURCEVERSION=${BUILD_SOURCEVERSION}" >> "${GITHUB_ENV}"
    fi
fi

export BUILD_SOURCEVERSION
