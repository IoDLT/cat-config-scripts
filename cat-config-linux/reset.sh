#!/bin/zsh

local script_src=$PWD/scripts/cat-config-linux
local catapult_server_src=$3

if [[ -z "$1" ]] then;
    echo "script must be called with one of the three options: --local | --existing | --foundation"
    return 0
    
    elif [[ -z "$2" ]] then;
    echo "script must be called with one of the three node types: api | peer | dual"
    return 0
fi

echo "Welcome to the Catapult Config Utility"

# reapply data directory
echo "+ preparing fresh data directory"
rm -rf $PWD/data
mkdir $PWD/data

# clear state directories
rm -rf state
rm -rf statedb

echo "<<< DONE"

# reset mongo
if [[ "peer" != "$1" ]] then;
    echo
    echo "+ resetting mongo"
    pushd .
    source ${script_src}/reset_mongo.sh ${catapult_server_src}
    popd
    echo "<<< DONE"
    echo
fi

# clear logs
echo "+ clearing logs"
touch catapult_server.reset.log # suppress glob errors by creating a file that always matches the glob
rm -f *.log
rm -rf logs

# recreate resources
echo "+ recreating resources"
rm -rf $PWD/resources
mkdir $PWD/resources

function setup_existing() {
    local generation_hash=$(grep "private key:" ${script_src}/templates/$2/generation_hash.txt | sed -e 's/private key://g' | tr -d ' ')
    source ${script_src}/prepare_resources.sh $1 $3 ${script_src}/templates/$2 $PWD/resources $4 $5 ${generation_hash}
    cp -R ${script_src}/templates/$2/seed/* $PWD/data
}

function setup_local() {
    
    echo "Generating network generation hash (UUID)"
    source ${script_src}/generate_hash.sh
    local generation_hash=$(grep "private key:" $PWD/generation_hash.txt | sed -e 's/private key://g' | tr -d ' ')
    
    echo "Preparing resources"
    source ${script_src}/prepare_resources.sh $1 $2 ${script_src}/templates/local $PWD/resources $3 $4 ${generation_hash}
    
    echo "Generating new nemesis block"
    source ${script_src}/prepare_nemesis_block.sh $2 $3 ${generation_hash}
}

function setup_foundation() {
    cp scripts/templates/foundation/foundation.peers.p2p.json resources/peers-p2p.json
    cp scripts/templates/foundation/foundation.peers.api.json resources/peers-api.json
}

while [[ 0 -ne $# ]]; do
    case "$1" in
        ## Prepares a standalone, single local node with its own completely new network
        --local)
            shift
            local node_type=$1
            local catapult_server_src=$2
            local boot_key=$3
            local public_key=$4
            
            setup_local ${node_type} ${catapult_server_src} ${boot_key} ${public_key}
        ;;
        
        ## Prepares a node that is capable of connecting to the Foundation network
        --foundation)
            ## Copy nemesis seed
            ## Copy resource files (provide root dir instead of catapult-server)
            ## Ready to start with start.sh
            setup_foundation
        ;;
        
        
        ## Prepare a node that is ready to connect to an existing network
        --existing)
            shift
            local node_type=$1
            local template_name=$2
            local catapult_server_src=$3
            local boot_key=$4
            local network_public_key=$5
            
            setup_existing ${node_type} ${template_name} ${catapult_server_src} ${boot_key} ${network_public_key}
            
        ;;
    esac
    shift
done
