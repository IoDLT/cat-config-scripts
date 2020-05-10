#!/bin/zsh
local script_src=$PWD/scripts/cat-config
local catapult_server_src=${CATAPULT_SERVER_ROOT}

if [[ -z "$1" ]] then;
    echo "script must be called with one of the three options: --local | --existing | --foundation"
    return 0
    
    elif [[ -z "$2" ]] then;
    echo "script must be called with one of the three node types: api | peer | dual"
    return 0
fi

echo "Welcome to the Catapult Config Utility"

# reapply data directory
echo "Preparing fresh data directory"
rm -rf $PWD/data
mkdir $PWD/data

if [ ! -f "/data/index.dat" ]; then
    echo "No index.dat file, creating now...."
    echo -ne "\01\0\0\0\0\0\0\0" > $PWD/data/index.dat
fi

echo "DONE CLEANING"

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
echo "Clearing logs"
touch catapult_server.reset.log # suppress glob errors by creating a file that always matches the glob
rm -f *.log
rm -rf logs

# recreate resources
echo "Recreating resources"
rm -rf $PWD/resources
mkdir $PWD/resources

# make dir structure
mkdir -p data nemesis resources scripts seed certs

function generate_cert() {
    echo "Generating TLS Certificate"
    echo
    source ${script_src}/generate_certificate.sh
}

function setup_existing() {
    generate_cert
    source ${script_src}/prepare_resources.sh $1 ${catapult_server_src} $3 ${script_src}/templates/$2 $PWD/resources
    cp -R ${script_src}/templates/$2/seed/* $PWD/data
}

function setup_local() {
    echo "Generating network generation hash (UUID)"
    echo
    source ${script_src}/generate_hash.sh $2
    local generation_hash=$(grep "private key:" $PWD/generation_hash.txt | sed -e 's/private key://g' | tr -d ' ')
    generate_cert
    echo "Preparing resources"
    echo
    source ${script_src}/prepare_resources.sh $1 ${catapult_server_src} ${script_src}/templates/local $PWD/resources $3 $4 ${generation_hash}
    
    echo "Generating new nemesis block"
    echo
    source ${script_src}/prepare_nemesis_block.sh ${catapult_server_src} $3 ${generation_hash}
}

function setup_official() {
    echo "Preparing official testnet resources"
    echo
    source ${script_src}/prepare_resources.sh $1 ${catapult_server_src} ${script_src}/templates/official $PWD/resources
    
    cp -R ${script_src}/templates/official/seed/* $PWD/data
    cp -R ${script_src}/templates/official/seed/* $PWD/seed
    generate_cert
    echo "Finished."
    echo
}

while [[ 0 -ne $# ]]; do
    case "$1" in
        ## Prepares a standalone, single local node with its own completely new network
        --local)
            shift
            local node_type=$1
            setup_local ${node_type}
        ;;
        
        ## Prepares a node that is capable of connecting to the offical network
        --offical)
            shift
            local node_type=$1
            setup_official ${node_type}
        ;;
        
        ## Prepare a node that is ready to connect to an existing network
        --existing)
            shift
            local node_type=$1
            local template_name=$2
            setup_existing ${node_type} ${template_name}
        ;;
    esac
    shift
done
