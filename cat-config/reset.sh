#!/bin/zsh
local script_src=$PWD/scripts/cat-config-mac
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
    local generation_hash=$(grep "private key:" $PWD/generation_hash.txt | sed -e 's/private key://g' | tr -d ' ')
    
    source ${script_src}/prepare_resources.sh $1 $3 ${script_src}/templates/$2 $PWD/resources $4 $5 ${generation_hash}
    cp -R ${script_src}/templates/$2/seed/* $PWD/data
}

function setup_local() {
    
    echo "Generating network generation hash (UUID)"
    echo
    source ${script_src}/generate_hash.sh $2
    local generation_hash=$(grep "private key:" $PWD/generation_hash.txt | sed -e 's/private key://g' | tr -d ' ')
    
    echo "Preparing resources"
    echo
    source ${script_src}/prepare_resources.sh $1 $2 ${script_src}/templates/local $PWD/resources $3 $4 ${generation_hash}
    
    echo "Generating new nemesis block"
    echo
    source ${script_src}/prepare_nemesis_block.sh $2 $3 ${generation_hash}
}

function setup_foundation() {
    echo "Preparing foundation resources"
    echo
    # Generation hash from configuration
    local generation_hash=CC42AAD7BD45E8C276741AB2524BC30F5529AF162AD12247EF9A98D6B54A385B
    local network_public_key=A3CE86263CD000F45867A6B5A396A521AF4557D9A6BD3C796478A9BF40BF4F4C
    source ${script_src}/prepare_resources.sh $1 $2 ${script_src}/templates/foundation $PWD/resources $3 ${network_public_key} ${generation_hash}
    
    cp -R ${script_src}/templates/foundation/seed/* $PWD/data
    cp -R ${script_src}/templates/foundation/seed/* $PWD/seed
    
    echo "Finished."
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
            shift
            local node_type=$1
            local catapult_server_src=$2
            local boot_key=$3
            local public_key=$4
            
            setup_foundation ${node_type} ${catapult_server_src} ${boot_key} ${public_key}
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
