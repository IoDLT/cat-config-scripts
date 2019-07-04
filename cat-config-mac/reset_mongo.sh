#!/bin/bash

catapult_source=$1

cd ${catapult_source}/scripts/mongo
echo "dropping mongo ..."
mongo catapult < mongoDbDrop.js

echo "preparing mongo ..."
mongo catapult < mongoDbPrepare.js
