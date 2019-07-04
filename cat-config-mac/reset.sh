#!/bin/zsh

local script_src=$PWD/scripts/cat-config-mac
local catapult_server_src=$2
local boot_key=$3
local public_key=$4

if [[ -z "$1" ]] then;
echo "script must be called with one of the three node types: api | peer | dual"
	return 0

elif [[ -z "$2" ]] then;
    echo "script must be called with your main catapult-server directory"
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

echo "Preparing resources"
source ${script_src}/prepare_resources.sh $1 ${catapult_server_src} $PWD/resources ${boot_key} ${public_key}


echo "Generating nemesis block"
source ${script_src}/prepare_nemesis_block.sh ${catapult_server_src} ${boot_key}


shift
while [[ 0 -ne $# ]]; do
	case "$1" in
			### broken for now, needs to be fixed up properly
		--local)
			cp ${script_src}/templates/local.peers.json resources/peers-p2p.json
			;;

			### broken for now, needs to be fixed up properly
		--stress)
			cp ${script_src}templates/stress.api.json resources/peers-api.json
			cp ${script_src}/templates/stress.peers.json resources/peers-p2p.json
			;;

			### broken for now, needs to be fixed up properly
		--foundation)
			source ${script_src}/prepare_resources.sh \
				"peer" \
				${catapult_server_src} \
				$PWD/resources

			cp /catapult/gits/catapult-service-bootstrap/data/peer-node-1/00000/* data/00000
			cp ${script_src}/../templates/foundation.peers.json resources/peers-p2p.json
			;;
	esac
	shift
done
