#!/bin/bash
# exit on error
set -e

# Default config
NML_BASENAME=${NML_BASENAME:-xussr}
NMLCOPTIONS=()
MIN_COMPATIBLE_REVISION=${MIN_COMPATIBLE_REVISION:-1}
CUSTOM_TAGS_FILE=${CUSTOM_TAGS_FILE:-custom_tags.txt}
# get version and revision
GRF_REVISION=${GRF_VERSION:-9999}
if [ -z "${GRF_VERSION}" ]; then
    GRF_VERSION="$(git describe --tags --dirty="+develop").r${GRF_REVISION}"
    GIT_IS_AVAILABLE=$?
    if [ $GIT_IS_AVAILABLE -ne 0 ]; then
        echo "Git is not installed. Please specify GRF_VERSION as env variable manually" >&2
        exit 1
    fi
fi
####


echo_err() {
    echo "$@" >&2
}

# $1 for subproject (rails, emu, dmu...)
# $2 for title
grf_compile() {
    if [ -z "${1}" ]; then
        NMLNAME="$NML_BASENAME"
    else
        NMLNAME="$NML_BASENAME-$1"
    fi

    # create tags
    echo "VERSION: $GRF_REVISION" > "$CUSTOM_TAGS_FILE"
    echo "TITLE: ${2:-xUSSR Set} $GRF_VERSION" >> "$CUSTOM_TAGS_FILE"
    echo "MIN_COMPATIBLE_REVISION: $MIN_COMPATIBLE_REVISION" >> "$CUSTOM_TAGS_FILE"
    echo "FILENAME: $NMLNAME" >> "$CUSTOM_TAGS_FILE"

    # gcc
    gcc -D REPO_REVISION="$GRF_REVISION" \
    -D MIN_COMPATIBLE_REVISION="$MIN_COMPATIBLE_REVISION" \
    -E -C -P -x c \
    -o "$NMLNAME.nml" \
    "$NMLNAME.pnml"

    # change.pl
    sed -i 's/) {/)\n{/g; s/} switch/}\nswitch/g; s/; /;\n/g' "$NMLNAME.nml"
    # nmlc
    [ ! -d "build" ] && mkdir build
    nmlc \
        --grf="build/$NMLNAME.grf" \
        -c \
        --nfo="build/$NMLNAME.nfo" \
        --nml="build/${NMLNAME}_optimized.nml" \
        -M --MF="build/${NMLNAME}_dep.txt" \
        "${NMLCOPTIONS[@]}" \
        "$NMLNAME.nml"

    rm -f "$NMLNAME.nml"
}

# prepare() {
    # replacement for clean-lng.pl
    # replacement for change.pl
    # gg
# }

monalise() {
    pushd lang
    perl scripts/MonaLisa.pl
    popd
}

grf_compile rails "xUSSR Rails Set"
# grf_compile addon "xUSSR Railway Set addon"
grf_compile diesel "xUSSR Railway Diesels Set"
grf_compile dmu "xUSSR Railway DMUs Set"
grf_compile electric "xUSSR Railway Electrics Set"
grf_compile emu "xUSSR Railway EMUs Set"
grf_compile steam "xUSSR Railway Steamers Set"
grf_compile wagons "xUSSR Railway Wagons Set"
grf_compile cars "xUSSR Railway Cars Set"