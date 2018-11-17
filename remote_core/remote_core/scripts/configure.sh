#!/bin/bash

usage() { echo "Usage: $0 [-d, --debug]" 1>&2; exit 1; }

DEBUG_BUILD=FALSE
if [[ "$1" == "-d" || "$1" == "--debug" ]]; then
    DEBUG_BUILD=TRUE
elif [ ! -z "$1" ]; then
    usage
fi

if [[ "$OSTYPE" == "linux-gnu" ]]; then
    P="uuid"
    dpkg -s "$P" >/dev/null 2>&1 && {
        echo "$P is installed."
    } || {
        echo "$P is not installed.\nWill attempt to install $P now."
        sudo apt-get install uuid-dev
    }

    P="ninja"
    dpkg -s "$P" >/dev/null 2>&1 && {
        echo "$P is installed."
    } || {
        echo "$P is not installed.\nWill attempt to install $P now."
        sudo apt-get install ninja-build
    }
fi

BUILD_DIR="build"
SEARCH_STRING="remote_core/remote_core"
ROOT_DIR="${PWD%$SEARCH_STRING*}"

cd "${ROOT_DIR}remote_core/remote_core"

if [ ! -d "$BUILD_DIR" ]; then
    mkdir "$BUILD_DIR"
fi

cd "$BUILD_DIR"

if [ "$DEBUG_BUILD" == "TRUE" ]; then
    echo "Configuring for debug build."
    cmake ../. -G Ninja -DCMAKE_BUILD_TYPE=Debug
else
    echo "Configuring for release build."
    cmake ../. -G Ninja -DCMAKE_BUILD_TYPE=Release
fi
