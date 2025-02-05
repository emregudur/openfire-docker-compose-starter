#!/bin/bash

usage() { echo "Usage: $0 [-n openfire-tag] [-h]
  -n openfire-tag  Launches all Openfire instances with the specified tag. This overrides the value in .env
  -h               Show this helpful information
"; exit 0; }

PROJECT="openfire"
COMPOSE_FILE_COMMAND=("docker" "compose")
COMPOSE_FILE_COMMAND+=("--env-file" "./_common/.env")
COMPOSE_FILE_COMMAND+=("--project-name" "$PROJECT")

# Where is this script? It could be called from anywhere, so use this to get full paths.
SCRIPTPATH="$( cd "$(dirname "$0")"; pwd -P )"

source "$SCRIPTPATH/_common/functions.sh"

check_deps

while getopts n:h o; do
  case "$o" in
    n)
        if [[ $OPTARG =~ " " ]]; then
          echo "Docker tags cannot contain spaces"
          exit 1
        fi
        echo "Using Openfire tag: $OPTARG"
        export OPENFIRE_TAG="$OPTARG"
        ;;
    h)  
        usage
        ;;
    *)
        usage
        ;;
  esac
done

echo "Starting a simple environment."
COMPOSE_FILE_COMMAND+=("-f" "docker-compose.yml")

pushd "$SCRIPTPATH"

"$SCRIPTPATH"/stop.sh
"${COMPOSE_FILE_COMMAND[@]}" pull --ignore-pull-failures

# Clean up temporary persistence data
if ! rm -rf _data; then 
  echo "ERROR: Failed to delete _data directory. Try with sudo, then re-run." && popd && exit 1
fi
mkdir _data
cp -r xmpp _data/
cp -r plugins _data/

"${COMPOSE_FILE_COMMAND[@]}" up -d || popd
popd