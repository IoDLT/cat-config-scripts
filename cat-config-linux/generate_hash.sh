#!/bin/zsh

local catapult_src=$1
local generation_hash_path=$PWD/generation_hash.txt

## Run address tool
${catapult_server_src}/build/bin/catapult.tools.address -n mijin-test -g 1 > "${generation_hash_path}"
