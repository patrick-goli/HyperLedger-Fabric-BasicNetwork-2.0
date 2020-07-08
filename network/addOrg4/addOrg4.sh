#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This script extends the Hyperledger Fabric test network by adding
# adding a third organization to the network
#

# prepending $PWD/../bin to PATH to ensure we are picking up the correct binaries
# this may be commented out to resolve installed version of tools if desired
export PATH=${PWD}/../../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
export VERBOSE=false

# Print the usage message
function printHelp () {
  echo "Usage: "
  echo "  addOrg4.sh up|down|generate [-c <channel name>] [-t <timeout>] [-d <delay>] [-f <docker-compose-file>] [-s <dbtype>]"
  echo "  addOrg4.sh -h|--help (print this message)"
  echo "    <mode> - one of 'up', 'down', or 'generate'"
  echo "      - 'up' - add org4 to the sample network. You need to bring up the test network and create a channel first."
  echo "      - 'down' - bring down the test network and org4 nodes"
  echo "      - 'generate' - generate required certificates and org definition"
  echo "    -c <channel name> - test network channel name (defaults to \"mychannel\")"
  echo "    -ca <use CA> -  Use a CA to generate the crypto material"
  echo "    -t <timeout> - CLI timeout duration in seconds (defaults to 10)"
  echo "    -d <delay> - delay duration in seconds (defaults to 3)"
  echo "    -s <dbtype> - the database backend to use: goleveldb (default) or couchdb"
  echo "    -i <imagetag> - the tag to be used to launch the network (defaults to \"latest\")"
  echo "    -cai <ca_imagetag> - the image tag to be used for CA (defaults to \"${CA_IMAGETAG}\")"
  echo "    -verbose - verbose mode"
  echo
  echo "Typically, one would first generate the required certificates and "
  echo "genesis block, then bring up the network. e.g.:"
  echo
  echo "	addOrg4.sh generate"
  echo "	addOrg4.sh up"
  echo "	addOrg4.sh up -c mychannel -s couchdb"
  echo "	addOrg4.sh down"
  echo
  echo "Taking all defaults:"
  echo "	addOrg4.sh up"
  echo "	addOrg4.sh down"
}

# We use the cryptogen tool to generate the cryptographic material
# (x509 certs) for the new org.  After we run the tool, the certs will
# be put in the organizations folder with org1 and org2

# Create Organziation crypto material using cryptogen or CAs
function generateOrg4() {

  # Create crypto material using cryptogen
  if [ "$CRYPTO" == "cryptogen" ]; then
    which cryptogen
    if [ "$?" -ne 0 ]; then
      echo "cryptogen tool not found. exiting"
      exit 1
    fi
    echo
    echo "##########################################################"
    echo "##### Generate certificates using cryptogen tool #########"
    echo "##########################################################"
    echo

    echo "##########################################################"
    echo "############ Create Org1 Identities ######################"
    echo "##########################################################"

    set -x
    cryptogen generate --config=org4-crypto.yaml --output="../organizations"
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate certificates..."
      exit 1
    fi

  fi

  # Create crypto material using Fabric CAs
  if [ "$CRYPTO" == "Certificate Authorities" ]; then

    fabric-ca-client version > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
      echo "ERROR! fabric-ca-client binary not found.."
      echo
      echo "Follow the instructions in the Fabric docs to install the Fabric Binaries:"
      echo "https://hyperledger-fabric.readthedocs.io/en/latest/install.html"
      exit 1
    fi

    echo
    echo "##########################################################"
    echo "##### Generate certificates using Fabric CA's ############"
    echo "##########################################################"

    IMAGE_TAG=${CA_IMAGETAG} docker-compose -f $COMPOSE_FILE_CA_ORG4 up -d 2>&1

    . fabric-ca/registerEnroll.sh

    sleep 10

    echo "##########################################################"
    echo "############ Create Org4 Identities ######################"
    echo "##########################################################"

    createOrg4

  fi

  echo
  echo "Generate CCP files for Org4"
  ./ccp-generate.sh
}

# Generate channel configuration transaction
function generateOrg4Definition() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
  fi
  echo "##########################################################"
  echo "#######  Generating Org4 organization definition #########"
  echo "##########################################################"
   export FABRIC_CFG_PATH=$PWD
   set -x
   configtxgen -printOrg Org4MSP > ../organizations/peerOrganizations/org4.example.com/org4.json
   res=$?
   set +x
   if [ $res -ne 0 ]; then
     echo "Failed to generate Org4 config material..."
     exit 1
   fi
  echo
}

function Org4Up () {
  # start org4 nodes
  if [ "${DATABASE}" == "couchdb" ]; then
    IMAGE_TAG=${IMAGETAG} docker-compose -f "$COMPOSE_FILE_ORG4" -f $COMPOSE_FILE_COUCH_ORG4 up -d 2>&1
  else
    IMAGE_TAG=${IMAGETAG} docker-compose -f "$COMPOSE_FILE_ORG4" up -d 2>&1
  fi
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Unable to start Org4 network"
    exit 1
  fi
}

# Generate the needed certificates, the genesis block and start the network.
function addOrg4 () {

  # If the test network is not up, abort
  if [ ! -d ../organizations/ordererOrganizations ]; then
    echo
    echo "ERROR: Please, run ./basicNetwork.sh up createChannel first."
    echo
    exit 1
  fi

  # generate artifacts if they don't exist
  if [ ! -d "../organizations/peerOrganizations/org4.example.com" ]; then
    generateOrg4
    generateOrg4Definition
  fi

  CONTAINER_IDS=$(docker ps -a | awk '($2 ~ /fabric-tools/) {print $1}')
  if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
    echo "Bringing up network"
    Org4Up
  fi

  # Use the CLI container to create the configuration transaction needed to add
  # Org4 to the network
  echo
  echo "###############################################################"
  echo "####### Generate and submit config tx to add Org4 #############"
  echo "###############################################################"

  docker exec Org4cli ./scripts/org4-scripts/step1org4.sh $CHANNEL_NAME $CLI_DELAY $CLI_TIMEOUT $VERBOSE
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Unable to create config tx"
    exit 1
  fi

  echo
  echo "###############################################################"
  echo "############### Have Org4 peers join network ##################"
  echo "###############################################################"
  docker exec Org4cli ./scripts/org4-scripts/step2org4.sh $CHANNEL_NAME $CLI_DELAY $CLI_TIMEOUT $VERBOSE
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Unable to have Org4 peers join network"
    exit 1
  fi

}

# Tear down running network
function networkDown () {

    cd ../..
    ./basicNetwork.sh down
}


# Obtain the OS and Architecture string that will be used to select the correct
# native binaries for your platform
OS_ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')
# timeout duration - the duration the CLI should wait for a response from
# another container before giving up

# Using crpto vs CA. default is cryptogen
CRYPTO="cryptogen"

CLI_TIMEOUT=10
#default for delay
CLI_DELAY=3
# channel name defaults to "mychannel"
CHANNEL_NAME="mychannel"
# use this as the docker compose couch file
COMPOSE_FILE_COUCH_ORG4=docker/docker-compose-couch-org4.yaml
# use this as the default docker-compose yaml definition
COMPOSE_FILE_ORG4=docker/docker-compose-org4.yaml
# certificate authorities compose file
COMPOSE_FILE_CA_ORG4=docker/docker-compose-ca-org4.yaml
# default image tag
IMAGETAG="latest"
# default ca image tag
CA_IMAGETAG="latest"
# database
DATABASE="leveldb"

# Parse commandline args

## Parse mode
if [[ $# -lt 1 ]] ; then
  printHelp
  exit 0
else
  MODE=$1
  shift
fi

# parse flags

while [[ $# -ge 1 ]] ; do
  key="$1"
  case $key in
  -h )
    printHelp
    exit 0
    ;;
  -c )
    CHANNEL_NAME="$2"
    shift
    ;;
  -ca )
    CRYPTO="Certificate Authorities"
    ;;
  -t )
    CLI_TIMEOUT="$2"
    shift
    ;;
  -d )
    CLI_DELAY="$2"
    shift
    ;;
  -s )
    DATABASE="$2"
    shift
    ;;
  -i )
    IMAGETAG=$(go env GOARCH)"-""$2"
    shift
    ;;
  -cai )
    CA_IMAGETAG="$2"
    shift
    ;;
  -verbose )
    VERBOSE=true
    shift
    ;;
  * )
    echo
    echo "Unknown flag: $key"
    echo
    printHelp
    exit 1
    ;;
  esac
  shift
done


# Determine whether starting, stopping, restarting or generating for announce
if [ "$MODE" == "up" ]; then
  echo "Add Org4 to channel '${CHANNEL_NAME}' with '${CLI_TIMEOUT}' seconds and CLI delay of '${CLI_DELAY}' seconds and using database '${DATABASE}'"
  echo
elif [ "$MODE" == "down" ]; then
  EXPMODE="Stopping network"
elif [ "$MODE" == "generate" ]; then
  EXPMODE="Generating certs and organization definition for Org4"
else
  printHelp
  exit 1
fi

#Create the network using docker compose
if [ "${MODE}" == "up" ]; then
  addOrg4
elif [ "${MODE}" == "down" ]; then ## Clear the network
  networkDown
elif [ "${MODE}" == "generate" ]; then ## Generate Artifacts
  generateOrg4
  generateOrg4Definition
else
  printHelp
  exit 1
fi
