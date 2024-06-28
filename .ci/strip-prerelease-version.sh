#!/usr/bin/env bash
function exit_error() {
    local exit_code=${1:-1}
    local message="${2}"
    [ ! -z "$message" ] && echo "$message"
    exit "$exit_code"
}

function strip_prerelease_version() {
    local version="${1%-*}"
    local yaml_file="${2}"
    temp_file=$(mktemp)
    yq ea ".version = \"${version}\"" $yaml_file > $temp_file
    mv $temp_file $yaml_file
}


function get_chart_yaml() {
    local chart_dir="${CHARTS_BASE_DIR}/${1}"
    if [ ! -d $chart_dir ]; then
        echo "Chart directory not found: $chart_dir" > /dev/stderr
        return 1
    fi
    local chart_file=$(find $chart_dir -maxdepth 1 \( -name "Chart.yaml" -o -name "Chart.yml" \) | head -1)
    if [ -z "$chart_file" ]; then
        echo "Chart.yml not found in $chart_dir" > /dev/stderr
        return 1
    fi
    
    echo $chart_file
    return 0
}

CHARTS_BASE_DIR=${CHARTS_BASE_DIR:-charts}
CHARTS=${CHARTS:-[]}
charts_input=$CHARTS
CHARTS=( $(yq --null-input e "${CHARTS}[]" 2> /dev/null )) || exit_error "1" "Malformed json: $charts_input"

if [ -z "${CHARTS}" ]; then
    CHARTS=()
    while IFS=  read -r -d $'\0'; do
        CHARTS+=($(basename $(dirname "$REPLY")))
    done < <(find $CHARTS_BASE_DIR -maxdepth 2 \( -name "Chart.yaml" -o -name "Chart.yml" \) -print0)
fi

for CHART in "${CHARTS[@]}" ; do
    yaml_file=$(get_chart_yaml $CHART) || continue
    CHART_VERSION=$(yq e '.version' ${yaml_file})
    strip_prerelease_version $CHART_VERSION $yaml_file
done
