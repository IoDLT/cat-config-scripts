#!/bin/zsh



local process_name=$1
local catapult_src=$2
local local_path=$PWD
shift

local use_debugger=0
while [[ 0 -ne $# ]]; do
	case "$1" in
		--force)
            rm -rf ${local_path}/data/${process_name}.lock
			;;
		--lldb)
			use_debugger=1
			;;
	esac
	shift
done

local process=${catapult_src}/build/bin/catapult.${process_name}
if [[ 0 -eq ${use_debugger} ]] then;
	${process} .
else
	lldb ${process} -- .
fi
