#!/bin/zsh

# generates the nemesis block properties file and nemesis block

local catapult_server_src=$1
local local_path=$PWD
local nemesis_signer_key=$2
local nemesis_path="/nemesis/nemesis-block.properties"
local harvester_keys_path="harvester_addresses.txt"


### From catapult-service-bootstrap
config_form() {
    local split=$(echo $1 | sed  's/\(.\)/\1 /g')
    local concat=$(printf "%c%c%c%c'" $(echo $split))
    echo "0x$concat[1,-2]"
}


function generate_addresses() {
    echo "generating addresses"
    ${catapult_server_src}/build/bin/catapult.tools.address -n "$1" -g "$2" > $harvester_keys_path
}

function run_sed() {
    local filename="$1.properties"
    echo "updating properties file"
    for key value in ${(kv)${(P)2}}; do
        sed -i "" -e "s#$key =.*#$key = $value#;" "${local_path}${nemesis_path}"
    done
}


function update_nemesis_block_file() {
    cp "${catapult_server_src}/tools/nemgen/resources/mijin-test.properties" "${local_path}${nemesis_path}"
    
    local -A nemesis_pairs=(
        "cppFile" ""
        "nemesisSignerPrivateKey" "$nemesis_signer_key"
        "binDirectory" "${local_path}/seed")

    run_sed "nemesis-block" nemesis_pairs 
    update_harvesters
    
}

function update_harvesters() {
    generate_addresses mijin-test 11
    
    if [[ ! -a $harvester_keys_path ]] then;
        echo "addresses file not generated"
        return 0;
    fi
    
    local new_harvester_addresses=( $(grep S $harvester_keys_path | sed -e 's/address (mijin-test)://g') )
    local old_harvester_addresses=( $(grep -i -A12 "\bdistribution>cat:harvest\b" "${local_path}${nemesis_path}" | grep -o -e "^S.\{40\}") )
    
    for i in {1..11}
    do
        sed -i "" -e "/\[distribution>cat:harvest\]/,/^\[/ s/$old_harvester_addresses[$i]/$new_harvester_addresses[$i]/g" "${local_path}${nemesis_path}"
    done
}


function nemgen() {
    update_nemesis_block_file
    
    ######## Nemgen script from catapult-service-bootstrap@https://github.com/tech-bureau/catapult-service-bootstrap
    
    if [ ! -d $local_path/data ]; then
        echo "/data directory does not exist"
        exit 1
    fi
    
    if [ ! -d $local_path/data/00000 ]; then
        echo "running nemgen"
        cd /tmp
        mkdir settings
        mkdir -p seed/mijin-test/00000
        dd if=/dev/zero of=seed/mijin-test/00000/hashes.dat bs=1 count=64
        cd settings
        ######## need to run twice and patch the mosaic ids
        # first time to get cat.harvest nad cat.currency
        ${catapult_server_src}/build/bin/catapult.tools.nemgen  --resources $local_path --nemesisProperties "${local_path}${nemesis_path}" 2> /tmp/nemgen.log
        local harvesting_mosaic_id=$(grep "cat.harvest" /tmp/nemgen.log | grep nonce  | awk -F=  '{split($0, a, / /); print a[9]}' | sort -u)
        local currency_mosaic_id=$(grep "cat.currency" /tmp/nemgen.log | grep nonce  | awk -F=  '{split($0, a, / /); print a[9]}' | sort -u)
        
        # second time after replacing values for currencyMosaicId and harvestingMosaicId
        sed -i '' -e "s/^harvestingMosaicId\ .*/harvestingMosaicId = $(config_form ${harvesting_mosaic_id})/" "$local_path/resources/config-network.properties"
        sed -i '' -e "s/^currencyMosaicId\ .*/currencyMosaicId = $(config_form ${currency_mosaic_id})/" "$local_path/resources/config-network.properties"
        ${catapult_server_src}/build/bin/catapult.tools.nemgen  --resources $local_path --nemesisProperties "${local_path}${nemesis_path}"
        
        cp -r /tmp/seed/mijin-test/* $local_path/data/
    else
        echo "no need to run nemgen"
    fi
    
}

nemgen
