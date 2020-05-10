#!/bin/zsh
# require zsh for associative arrays
local role=$1
local catapult_server_src=$2
local catapult_exec=${CATAPULT_BIN}
local resources_src=$3
local resources_dest=$4
local local_path=$PWD

local sed_flags=()
if [[ "$OSTYPE" == "linux-gnu" ]]; then
    sed_flags+=("-i" "-e")
    elif [[ "$OSTYPE" == "darwin"* ]]; then
    sed_flags+=("-i" "\"\"" "-e")
fi

echo "SED FLAGS"
echo ${sed_flags[@]}
echo

function copy_peers() {
    local filename="peers-$1.json"
    echo "copying ${filename}"
    cp "${resources_src}/resources/${filename}" "${resources_dest}/${filename}"
}

function copy_properties() {
    local filename="config-$1.properties"
    echo "copying ${filename}"
    cp "${resources_src}/resources/${filename}" "${resources_dest}/${filename}"
}

function run_sed() {
    local filename="config-$1.properties"
    echo "updating ${filename}"
    
    # using "#" for delimiters so as to be friendly to paths
    for key value in ${(kv)${(P)2}}; do
        sed ${sed_flags[@]} "s#$key =.*#$key = $value#;" ${resources_dest}/${filename}
    done
}

function set_extensions() {
    local filename="config-$1.properties"
    echo "updating extensions in ${filename}"
    
    for key in ${(k)${(P)3}}; do
        sed ${sed_flags[@]} "s/extension.$key = .*/extension.$key = $2/;" ${resources_dest}/${filename}
    done
}

function prepare_base_resources() {
    copy_peers "p2p"
    
    for extension in "extensions-server" "inflation" "logging-recovery" "extensions-recovery" "logging-server" "network" "networkheight" "node" "task" "timesync" "user"; do
        copy_properties ${extension}
    done
    
    local -A node_pairs=(
        "enableCacheDatabaseStorage" "true"
        "unconfirmedTransactionsCacheMaxSize" "10'000'000"
        "connectTimeout" "15s"
    "syncTimeout" "120s")
    run_sed "node" node_pairs
    
    local -A user_pairs=(
        "certificateDirectory" "$PWD/certs"
        "dataDirectory" "$local_path/data"
    "pluginsDirectory" "$catapult_exec")
    run_sed "user" user_pairs
}

function prepare_api_resources() {
    copy_peers "api"
    
    for extension in "extensions-broker" "logging-broker" "database" "messaging" "pt"; do
        copy_properties ${extension}
    done
    
    local -A logging_pairs=(
        "level" "Debug"
    "sinkType" "Async")
    run_sed "logging-broker" logging_pairs
    
    local -A node_pairs=(
        "enableAutoSyncCleanup" "false"
        "friendlyName" "{INSERT_API_NAME}"
    "roles" "Api")
    run_sed node node_pairs
    
    local api_extensions=("filespooling" "partialtransaction")
    local p2p_extensions=("eventsource" "harvesting" "syncsource")
    
    set_extensions "extensions-server" "true" api_extensions
    set_extensions "extensions-server" "false" p2p_extensions
}

function prepare_peer_resources() {
    for extension in "harvesting"; do
        copy_properties ${extension}
    done
    
    local -A node_pairs=(
        "enableSingleThreadPool" "true"
        "friendlyName" "{INSERT_PEER_NAME}"
    "roles" "Peer")
    run_sed node node_pairs
    
    local -A harvesting_pairs=(
        "harvesterPrivateKey" "{INSERT_HARVESTER_KEY}"
    "enableAutoHarvesting" "true")
    run_sed harvesting harvesting_pairs
}

function prepare_dual_resources() {
    local -A node_pairs=(
        "friendlyName" "{INSERT_DUAL_NAME}"
    "roles" "Api, Peer")
    run_sed node node_pairs
    
    local p2p_extensions=("eventsource" "harvesting" "syncsource")
    set_extensions extensions-server "true" p2p_extensions
}

echo "[PREPARING ${role} NODE CONFIGURATION]"

prepare_base_resources

case "${role}" in
    "api")
        prepare_api_resources
    ;;
    
    "peer")
        prepare_peer_resources
    ;;
    
    "dual")
        prepare_api_resources
        prepare_peer_resources
        prepare_dual_resources
    ;;
    *)
    ;;
esac

