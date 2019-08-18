#!/bin/zsh
# require zsh for associative arrays

local catapult_server_src=$2
local resources_src=$3
local resources_dest=$4
local boot_key=$5
local public_key=$6
local generation_hash=$7
local local_path=$PWD

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
        sed -i "" -e "s#$key =.*#$key = $value#;" ${resources_dest}/${filename}
	done
}

function set_extensions() {
	local filename="config-$1.properties"
	echo "updating extensions in ${filename}"

	for key in ${(k)${(P)3}}; do
        sed -i "" -e "s/extension.$key = .*/extension.$key = $2/;" ${resources_dest}/${filename}
	done
}

function prepare_base_resources() {
	copy_peers "p2p"

	for extension in "extensions-server" "inflation" "logging-recovery" "extensions-recovery" "logging-server" "network" "networkheight" "node" "task" "timesync" "user"; do
		copy_properties ${extension}
	done

	local -A logging_pairs=(
		"level" "Debug"
		"sinkType" "Async")
	run_sed "logging-server" logging_pairs

	local -A node_pairs=(
		"shouldUseCacheDatabaseStorage" "true"
		"unconfirmedTransactionsCacheMaxSize" "10'000'000"
		"connectTimeout" "15s"
		"syncTimeout" "120s")
	run_sed "node" node_pairs


    local -A network_pairs=(
		"generationHash" "$generation_hash"
        "publicKey" "$public_key"
        "totalChainImportance" "17'000'000"
        "initialCurrencyAtomicUnits" "8'999'999'998'000'000"
    )

    run_sed "network" network_pairs

	local -A user_pairs=(
		"bootKey" "$boot_key"
		"dataDirectory" "$local_path/data"
        "pluginsDirectory" "$catapult_server_src/build/bin")
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
		"shouldEnableAutoSyncCleanup" "false"
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
		"shouldUseSingleThreadPool" "true"
		"friendlyName" "{INSERT_PEER_NAME}"
		"roles" "Peer")
	run_sed node node_pairs

	local -A harvesting_pairs=(
		"harvestKey" "{INSERT_HARVESTER_KEY}"
		"isAutoHarvestingEnabled" "true")
	run_sed harvesting harvesting_pairs
}

function prepare_dual_resources() {
	local -A node_pairs=(
        "friendlyName" "{INSERT_DUAL_NAME}"
		"roles" "Api, Peer")
	run_sed node node_pairs

	local -A database_pairs=("shouldPruneFileStorage" "false")
	run_sed database database_pairs

	local p2p_extensions=("eventsource" "harvesting" "syncsource")
	set_extensions extensions-server "true" p2p_extensions
}

echo "[PREPARING $1 NODE CONFIGURATION]"

prepare_base_resources

case "$1" in
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

