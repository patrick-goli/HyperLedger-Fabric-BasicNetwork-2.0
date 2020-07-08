# Print the usage message
function printHelp() {
  echo "Usage: "
  echo "  basicnetwork.sh <Mode>"
  echo "    <Mode>"
  echo "      - 'up' - bring up fabric orderer and peer nodes. No channel is created"
  echo "      - 'createChannel' - create and join a channel after the network is created"
  echo "      - 'deployCC' - deploy the fabcar chaincode on the channel"
  echo "      - 'down' - clear the network with docker-compose down"
  echo "      - 'restart' - restart the network"
}

generateCryptoMaterials() {
  echo "=====================GENERATING CRYPTO MATERIALS====================="
  pushd ./network/ || return
  ./generate-crypto.sh
  popd || return
}

deployCC() {
  echo "=====================DEPLOYING CHAINCODE====================="
  pushd ./network/ || return
  ./deployChaincode.sh
  popd || return
}

# Do some basic sanity checking to make sure that the appropriate versions of fabric
# binaries/images are available. In the future, additional checking for the presence
# of go or other items could be added.
function checkPrereqs() {

  # Versions of fabric known not to work with the test network
  BLACKLISTED_VERSIONS="^1\.0\. ^1\.1\. ^1\.2\. ^1\.3\. ^1\.4\."
  ## Check if your have cloned the peer binaries and configuration files.
  peer version >/dev/null 2>&1

  if [[ $? -ne 0 ]]; then
    echo "ERROR! Peer binary and configuration files not found.."
    echo
    echo "Follow the instructions in the Fabric docs to install the Fabric Binaries:"
    echo "https://hyperledger-fabric.readthedocs.io/en/latest/install.html"
    exit 1
  fi
  # use the fabric tools container to see if the samples and binaries match your
  # docker images
  LOCAL_VERSION=$(peer version | sed -ne 's/ Version: //p')
  DOCKER_IMAGE_VERSION=$(docker run --rm hyperledger/fabric-tools:$IMAGETAG peer version | sed -ne 's/ Version: //p' | head -1)

  echo "LOCAL_VERSION=$LOCAL_VERSION"
  echo "DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION"

  if [ "$LOCAL_VERSION" != "$DOCKER_IMAGE_VERSION" ]; then
    echo "=================== WARNING ==================="
    echo "  Local fabric binaries and docker images are  "
    echo "  out of  sync. This may cause problems.       "
    echo "==============================================="
  fi

  for UNSUPPORTED_VERSION in $BLACKLISTED_VERSIONS; do
    echo "$LOCAL_VERSION" | grep -q $UNSUPPORTED_VERSION
    if [ $? -eq 0 ]; then
      echo "ERROR! Local Fabric binary version of $LOCAL_VERSION does not match the versions supported by the test network."
      exit 1
    fi

    echo "$DOCKER_IMAGE_VERSION" | grep -q $UNSUPPORTED_VERSION
    if [ $? -eq 0 ]; then
      echo "ERROR! Fabric Docker image version of $DOCKER_IMAGE_VERSION does not match the versions supported by the test network."
      exit 1
    fi
  done
}

# Tear down running network
function networkDown() {
  # stop org3 containers also in addition to org1 and org2, in case we were running sample to add org3
  docker-compose -f "$COMPOSE_FILE_BASE" down --volumes --remove-orphans

  # Delete existing artifacts
  if [ -d "./network/organizations/peerOrganizations" ]; then
      rm -rf ./network/organizations/peerOrganizations
  fi

  if [ -d "./network/organizations/ordererOrganizations" ]; then
      rm -rf ./network/organizations/ordererOrganizations
  fi

  if [ -d "./network/channel-artifacts" ]; then
      rm -rf ./network/channel-artifacts/*
  fi

  if [ -d "./api-2.0/config" ]; then
      rm ./api-2.0/config/connection-org*
  fi

  rm -f ./network/log.txt ./network/fabcar.tar.gz
}

networkUp() {
  checkPrereqs
  # generate artifacts if they don't exist
  if [ ! -d "network/organizations/peerOrganizations" ]; then
    generateCryptoMaterials
  fi
  echo "=====================BRINGING UP THE NETWORK====================="
  docker-compose -f "$COMPOSE_FILE_BASE" up -d
}

createChannel(){
  pushd ./network/ || return
  ./createChannel.sh "$CHANNEL_NAME"
  popd || return
}

############################################################################
############################################################################
IMAGETAG="2.1"
# channel name defaults to "mychannel"
CHANNEL_NAME="mychannel"
# use this as the default docker-compose yaml definition
COMPOSE_FILE_BASE=network/docker/docker-compose.yaml

# Parse commandline args

## Parse mode
if [[ $# -lt 1 ]]; then
  printHelp
  exit 0
else
  MODE=$1
  shift
fi

if [ "${MODE}" == "up" ]; then
  networkUp
elif [ "${MODE}" == "createChannel" ]; then
  createChannel
elif [ "${MODE}" == "deployCC" ]; then
  deployCC
elif [ "${MODE}" == "down" ]; then
  echo "Shutting down..."
  networkDown
elif [ "${MODE}" == "restart" ]; then
  echo "Restarting..."
  networkDown
  networkUp
elif [ "${MODE}" == "all" ]; then
  networkUp
  createChannel
  deployCC

else
  printHelp
  exit 1
fi
