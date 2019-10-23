#!/bin/bash

catapult_source=$1

cd ${catapult_source}/scripts/mongo
echo "dropping mongo ..."
mongo "${REMOTE_MONGODB_HOST:-127.0.0.1:27017}"/catapult < mongoDbDrop.js
echo "preparing mongo ..."
mongo "${REMOTE_MONGODB_HOST:-127.0.0.1:27017}"/catapult < mongoDbPrepare.js
