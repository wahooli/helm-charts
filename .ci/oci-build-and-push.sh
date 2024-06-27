#!/usr/bin/env bash
function exit_error() {
    local exit_code=${1:-1}
    local message="${2}"
    [ ! -z "$message" ] && echo "$message"
    exit "$exit_code"
}

function bump_prerelease_version() {
    local version="${1}"
    if [ "${version%-*}" == "$version" ]; then
        echo "${version}-1"
    else
        echo "${version%-*}-$((${version##*-}+1))"
    fi
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
BUILD_PRERELEASE=${BUILD_PRERELEASE:-true}
FORCE_PUSH=${FORCE_PUSH:-false}
CHARTS=${CHARTS:-[]}
charts_input=$CHARTS
GITHUB_ACTOR=$GITHUB_ACTOR
GITHUB_ACTOR_ID=$GITHUB_ACTOR_ID
GITHUB_TOKEN=$GITHUB_TOKEN
GITHUB_REPO=${GITHUB_REPO:-wahooli/helm-charts}
OCI_REGISTRY=${OCI_REGISTRY:-ghcr.io}
CHARTS=( $(yq --null-input e "${CHARTS}[]" 2> /dev/null )) || exit_error "1" "Malformed json: $charts_input"

if [ "${BUILD_PRERELEASE,,}" == "true" ]; then
    if ! command -v git &> /dev/null; then
        echo "git: command not found!"
        exit 1
    fi
    if [ ! -d ".git" ]; then
        echo ".git directory not found!"
        exit 1
    fi
    if [ -z "$(git config user.name)" ]; then
        git config --global user.name "${GITHUB_ACTOR}"
        git config --global user.email "${GITHUB_ACTOR_ID}+${GITHUB_ACTOR}@users.noreply.github.com"

        if [ ! -z "$GITHUB_TOKEN" ]; then
            git remote set-url --push origin https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPO}
        fi
    fi
fi

if [ -z "${CHARTS}" ]; then
    CHARTS=()
    while IFS=  read -r -d $'\0'; do
        CHARTS+=($(basename $(dirname "$REPLY")))
    done < <(find $CHARTS_BASE_DIR -maxdepth 2 \( -name "Chart.yaml" -o -name "Chart.yml" \) -print0)
fi

mkdir -p output

for CHART in "${CHARTS[@]}" ; do
    ALLOW_PUSH=${FORCE_PUSH:-false}
    yaml_file=$(get_chart_yaml $CHART) || continue
    CHART_VERSION=$(yq e '.version' ${yaml_file})
    if [ "${BUILD_PRERELEASE,,}" == "true" ]; then
        CHART_VERSION=$(bump_prerelease_version "${CHART_VERSION}")
        temp_file=$(mktemp)
        yq ea ".version = \"${CHART_VERSION}\"" $yaml_file > $temp_file
        mv $temp_file $yaml_file
        git add $yaml_file
        # yq ".version = \"${CHART_VERSION}\"" $yaml_file && \
        # git add $yaml_file
    fi

    if [ "${FORCE_PUSH,,}" == "false" ]; then
        if ! helm show chart oci://${OCI_REGISTRY}/${GITHUB_ACTOR}/charts/${CHART} --version $CHART_VERSION > /dev/null 2>&1; then
            ALLOW_PUSH="true"
        fi
    fi

    if [ "${ALLOW_PUSH,,}" == "true" ]; then
        helm package "${CHARTS_BASE_DIR}/${CHART}" --destination output/ --dependency-update --version "${CHART_VERSION}"
        helm push "output/${CHART}-${CHART_VERSION}.tgz" oci://${OCI_REGISTRY}/${GITHUB_ACTOR}/charts
    else
        echo "Skipping push, since chart \"${CHART}\" with version \"${CHART_VERSION}\" already exists."
    fi
done

if ! git diff --cached --quiet; then
    git commit -m "[no ci] Bump chart versions"
    git push
fi