#!/bin/bash
# exit on error
set -e

# Default config
NML_BASENAME=${NML_BASENAME:-xussr}
NMLCOPTIONS=()
MIN_COMPATIBLE_REVISION=${MIN_COMPATIBLE_REVISION:-1}
CUSTOM_TAGS_FILE=${CUSTOM_TAGS_FILE:-custom_tags.txt}
BUMP_REVISION=0
DELETE_NML_FILE=0

_print_help() {
    cat >&2 << EOF
    compile.sh - a script to compile xUSSR GRF files

    Usage: $(basename "$0") [options...] <modules to compile>
      -h, --help             Show this message
      -b, --bump-revision    Bump revision before compilation
      -M, --min-revision     Set minimal compatible revision (default: $MIN_COMPATIBLE_REVISION)
      -B, --basename         Set default GRF basename (default: $NML_BASENAME)
      -V, --grf-version      Manually set GFR version (when git is not available)
      -D, --delete-nml       Delete NML-file after the compilation

    Special module names:
      all - compile all known modules
      combined - compile combined grf
EOF
}

PARSED_ARGS=$(getopt -o "hbM:B:V:D" -l "help,bump-revision,min-revision:,basename:,grf-version:,delete-nml" -- "$@")
if [[ $? -ne 0 ]]; then
    _print_help
    exit 1;
fi

eval set -- "$PARSED_ARGS"

while [ : ]; do
    case "$1" in
        -h | --help)
            _print_help
            exit 0
            ;;
        -b | --bump-revision)
            BUMP_REVISION=1
            shift
            ;;
        -M | --min-revision)
            MIN_COMPATIBLE_REVISION=${2}
            shift 2
            ;;
        -B | --basename)
            NML_BASENAME=${2}
            shift 2
            ;;
        -V | --grf-version)
            GRF_VERSION=${2}
            shift 2
            ;;
        -D | --delete-nml)
            DELETE_NML_FILE=1
            shift
            ;;
        --)
            shift
            break
            ;;
    esac
done

echo_err() {
    echo "$@" >&2
}

if [ $# -eq 0 ]; then
    echo_err "No modules to build. Please provide at least one"
    exit 1
fi

# generate version string
if [ -z "${GRF_VERSION}" ]; then
    GRF_VERSION="$(git describe --tags --dirty="+develop")"
    GIT_IS_AVAILABLE=$?
    if [ $GIT_IS_AVAILABLE -ne 0 ]; then
        echo "Git is not installed. Please specify GRF_VERSION as env variable manually" >&2
        exit 1
    fi
fi
####

# $1 for subproject (rails, emu, dmu...)
# $2 for title
grf_compile() {
    if [ -z "${1}" ]; then
        NMLNAME="$NML_BASENAME"
    else
        NMLNAME="$NML_BASENAME-$1"
    fi
    if [ -f "versions/xussr-$1.ver" ]; then
        GRF_REVISION=$(cat "versions/xussr-$1.ver")
    else
        GRF_REVISION=1
    fi

    # create tags
    echo "VERSION: $GRF_REVISION" > "$CUSTOM_TAGS_FILE"
    echo "TITLE: ${2:-xUSSR Set} ${GRF_VERSION}.r${GRF_REVISION}" >> "$CUSTOM_TAGS_FILE"
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

declare -A XUSSR_MODULE_NAMES=(
    ["rails"]="xUSSR Rails Set"
    ["addon"]="xUSSR Railway Set Addon"
    ["diesel"]="xUSSR Railway Diesels Set"
    ["dmu"]="xUSSR Railway DMUs Set"
    ["electric"]="xUSSR Railway Electrics Set"
    ["emu"]="xUSSR Railway EMUs Set"
    ["steam"]="xUSSR Railway Steamers Set"
    ["wagons"]="xUSSR Railway Wagons Set"
    ["cars"]="xUSSR Railway Cars Set"
)

for grf_module in "$@"; do
    if [[ "$grf_module" == "combined" ]]; then
        echo "Compiling $NML_BASENAME..."
        grf_compile
        continue
    fi

    if [[ "$grf_module" == "all" ]]; then
        echo "Compiling all known modules"
        for known_module in "${!XUSSR_MODULE_NAMES[@]}"; do
            echo "Compiling $NML_BASENAME-$known_module..."
            grf_compile "$known_module" "${XUSSR_MODULE_NAMES["$known_module"]}"
        done
        continue
    fi

    echo "Compiling $NML_BASENAME-$grf_module..."
    TMP_GRF_NAME=${XUSSR_MODULE_NAMES["$grf_module"]}
    [ -z "${TMP_GRF_NAME}" ] && TMP_GRF_NAME="$grf_module"
    grf_compile "$grf_module" "$TMP_GRF_NAME"
done
